import os
import json
import argparse
import requests
import uuid

def generate_blueprint(genre, theme, age_range, api_key):
    print(f"Generating {genre} blueprint for theme '{theme}' (Age: {age_range})...")
    
    with open("PROMPT_TEMPLATE.md", "r", encoding="utf-8") as f:
        prompt_template = f.read()
    
    prompt = prompt_template.replace("{GENRE}", genre).replace("{THEME}", theme).replace("{AGE_RANGE}", age_range)
    
    # Request to Gemini API
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
    
    headers = {
        "Content-Type": "application/json"
    }
    
    payload = {
        "contents": [{
            "parts": [{"text": prompt}]
        }],
        "generationConfig": {
            "temperature": 0.9,
            "responseMimeType": "application/json"
        }
    }
    
    response = requests.post(url, headers=headers, json=payload)
    
    if response.status_code != 200:
        print(f"Error from API: {response.text}")
        return
        
    response_json = response.json()
    try:
        content = response_json['candidates'][0]['content']['parts'][0]['text']
    except (KeyError, IndexError):
        print(f"Failed to parse response: {response_json}")
        return
        
    # Verify it's valid JSON
    try:
        blueprint_data = json.loads(content)
        blueprint_id = blueprint_data.get("blueprint", {}).get("id", f"{genre}_{theme}_{str(uuid.uuid4())[:8]}")
        
        # Save to the correct directory
        output_dir = "../../StoryEngine/Sources/StoryEngine/Resources/templates/offline"
        os.makedirs(output_dir, exist_ok=True)
        
        output_path = os.path.join(output_dir, f"{blueprint_id}.json")
        with open(output_path, "w", encoding="utf-8") as out_f:
            json.dump(blueprint_data, out_f, indent=2, ensure_ascii=False)
            
        print(f"✅ Successfully generated and saved to: {output_path}")
        
    except json.JSONDecodeError as e:
        print(f"Failed to decode JSON from AI. The AI might have outputted invalid JSON. Error: {e}")
        print("Raw output:")
        print(content)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="MagicPaper Story Content Creator")
    parser.add_argument("--genre", type=str, default="adventure", help="Genre of the story")
    parser.add_argument("--theme", type=str, required=True, help="Theme (e.g. courage, friendship)")
    parser.add_argument("--age", type=str, default="5-6", choices=["3-4", "5-6", "7-8"], help="Age range")
    
    args = parser.parse_args()
    
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("❌ Error: GEMINI_API_KEY environment variable is missing.")
        print("Please run: export GEMINI_API_KEY='your_key'")
        exit(1)
        
    generate_blueprint(args.genre, args.theme, args.age, api_key)
