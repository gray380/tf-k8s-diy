import os
import json
import urllib.request
import sys

def list_files():
    token = os.environ.get('GITHUB_TOKEN')
    if not token:
        try:
            with open('terraform.tfvars', 'r') as f:
                for line in f:
                    if 'github_token' in line:
                        token = line.split('=')[1].strip().replace('"', '')
                        break
        except:
            pass
    
    if not token:
        print("Error: GITHUB_TOKEN not found")
        sys.exit(1)

    repo = "gray380/flux-config-gke"
    url = f"https://api.github.com/repos/{repo}/git/trees/main?recursive=1"
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"token {token}")
    
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            tree = data.get('tree', [])
            for item in tree:
                print(item['path'])
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    list_files()
