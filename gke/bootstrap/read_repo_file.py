import os
import json
import urllib.request
import sys

def read_file(path):
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
    url = f"https://api.github.com/repos/{repo}/contents/{path}"
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"token {token}")
    
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            content = data.get('content', '')
            import base64
            print(base64.b64decode(content).decode())
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        read_file(sys.argv[1])
