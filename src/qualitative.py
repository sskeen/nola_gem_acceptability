# qualitative.py
# Deductive qualitative coding functions for LLM-assisted analysis
# Simone J. Skeen x Claude Code

import json
import time

import pandas as pd
import requests
import yaml
from sklearn.metrics import cohen_kappa_score


def load_coding_schema(yaml_path):
    '''
    Loads coding schema from YAML file.

    Parameters:
    -----------
    yaml_path : str or Path
        Path to the YAML schema file.

    Returns:
    --------
    dict
        Dictionary containing role, codes, and their definitions/examples.
    '''
    with open(yaml_path, 'r') as f:
        return yaml.safe_load(f)


def build_prompt(code, alias, code_def, code_ex, role=None):
    '''
    Constructs a deductive coding prompt for LLM-based qualitative analysis.

    Parameters:
    -----------
    code : str
        Full name of the qualitative code (e.g., 'JITAI recognition').
    alias : str
        Short alias for column naming (e.g., 'strs').
    code_def : str
        Definition of what the code captures, including inclusion/exclusion criteria.
    code_ex : str
        Human-validated examples of text that should receive this code.
    role : str, optional
        Role/context prompt. If None, uses default.

    Returns:
    --------
    str
        Complete prompt string ready for LLM consumption.
    '''
    if role is None:
        role = '''
    You are tasked with applying pre-defined qualitative codes to segments of text excerpted
    from interviews with users of a mental health app for people living with HIV.

    The app included text-messaged surveys multiple times a day, as well as self-directed sessions
    on mindfulness meditation, trauma psychoeducation (etc.), and momentary prompts to engage with
    brief coping skills training as needed throughout the day.

    You will be provided a definition, instructions, and
    key exemplars of text to guide your coding decisions.
    '''

    text = '''
    ---
    Text to classify:
    "{text}"
    ---
    '''

    definition = f'''
    Definition of "{code}": {code_def}.
    '''

    instruction = f'''
    You will be provided with a piece of text. For each piece of text:
    - If it meets the definition of "{code}," output {alias}_llm as "1".
    - Otherwise, output {alias}_llm as "0".
    - Also provide a short explanation in exactly two sentences, stored in {alias}_expl.

    Please respond in valid JSON with keys "{alias}_llm" and "{alias}_expl" only.
    '''

    example = f'''
    Below are human-validated examples of "{code}"

    - "{code_ex}"
    '''

    return f'{role}{definition}{instruction}{text}{example}'


def build_prompt_from_schema(schema, alias):
    '''
    Builds a prompt from a loaded YAML schema for a specific code alias.

    Parameters:
    -----------
    schema : dict
        Loaded YAML schema dictionary.
    alias : str
        Code alias to build prompt for.

    Returns:
    --------
    str
        Complete prompt string ready for LLM consumption.
    '''
    role = schema.get('role', '')
    code_info = schema['codes'].get(alias, {})

    return build_prompt(
        code=code_info.get('name', alias),
        alias=alias,
        code_def=code_info.get('definition', ''),
        code_ex='\n        - '.join(code_info.get('examples', [])),
        role=role
    )


def code_texts_deductively_ollama(df, alias, text_column, endpoint_url, prompt_template, model_name):
    '''
    Classifies each row of 'text' column in provided df in accord with human-specified prompt,
    includes chain-of-thought reasoning, returning explanations for classification decision.

    Parameters:
    -----------
    df : pd.DataFrame
        df containing the text to classify.
    alias : str
        alias (for brevity) of the qualitative code to be applied.
    text_column : str
        column name in df containing the text to be analyzed.
    endpoint_url : str
        URL where locally hosted LLM runs.
    prompt_template : str
        prompt text with a placeholder (e.g. '{text}') where the row's text will be inserted.
    model_name : str
        model tasked with qualitative deductive coding.

    Returns:
    --------
    df : pd.DataFrame
        The original df with two new columns per deductive code: '{alias}_llm' (either "0" or "1")
        and '{alias}_expl' (the chain-of-thought explanation)
    '''
    label_column = f'{alias}_llm'
    explanation_column = f'{alias}_expl'

    df[label_column] = None
    df[explanation_column] = None

    results = []

    for idx, row in df.iterrows():
        row_text = row[text_column]

        unique_id = f"[Row ID: {idx}]"
        prompt = f"{unique_id}\n\n" + prompt_template.format(text=row_text)

        response = requests.post(
            endpoint_url,
            headers={'Content-Type': 'application/json'},
            json={
                'model': model_name,
                'prompt': prompt,
                'stream': False
            })

        print(f"\n--- Index {idx} ---")
        print("Prompt:")
        print(prompt)
        print(f"Status: {response.status_code}")
        print("Raw response:")
        print(response.text)

        label = None
        explanation = None

        if response.status_code == 200:
            try:
                result_json = response.json()
                raw_response_str = result_json.get('response', ' ')

                cleaned_str = raw_response_str.strip().replace("```json", " ").replace("```", " ").strip()
                parsed_output = json.loads(cleaned_str)

                label = parsed_output.get(label_column)
                explanation = parsed_output.get(explanation_column)

            except (json.JSONDecodeError, KeyError, TypeError) as e:
                print("JSON error:", e)
                print("Bad string:")
                print(cleaned_str)

        results.append({
            'idx': idx,
            label_column: label,
            explanation_column: explanation
            })

        time.sleep(0.25)

    result_df = pd.DataFrame(results).set_index('idx')
    df.update(result_df)

    return df


def calculate_kappa(df, col1, col2):
    '''
    Computes Cohen's kappa between two columns.
    '''
    return cohen_kappa_score(df[col1], df[col2])


def calculate_percent_agreement(df, col_pairs):
    '''
    Computes percent agreement for a list of column pairs.
    '''
    results = {}
    for col1, col2 in col_pairs:
        agreement = df[col1] == df[col2]
        percent_agreement = (agreement.sum() / len(df)) * 100
        results[f"{col1} & {col2}"] = percent_agreement
    return results


def encode_disagreements(row):
    '''
    Returns 1 if two values disagree, 0 otherwise.
    '''
    return 1 if row[0] != row[1] else 0
