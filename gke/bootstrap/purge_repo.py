import os
import json
import urllib.request
import sys

def delete_path(path):
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
    headers = {"Authorization": f"token {token}", "Content-Type": "application/json"}
    
    # Get recursive tree to find all files starting with path
    url_tree = f"https://api.github.com/repos/{repo}/git/trees/main?recursive=1"
    req_tree = urllib.request.Request(url_tree, headers=headers)
    
    try:
        with urllib.request.urlopen(req_tree) as resp:
            data = json.loads(resp.read().decode())
            tree = data.get('tree', [])
            for item in tree:
                if item['path'].startswith(path) and item['type'] == 'blob':
                    # Delete each file
                    file_path = item['path']
                    sha = item['sha']
                    url_del = f"https://api.github.com/repos/{repo}/contents/{file_path}"
                    body = json.dumps({
                        "message": f"Purging {file_path} for clean bootstrap",
                        "sha": sha,
                        "branch": "main"
                    }).encode()
                    req_del = urllib.request.Request(url_del, data=body, headers=headers, method='DELETE')
                    with urllib.request.urlopen(req_del) as d_resp:
                        print(f"Deleted {file_path}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    delete_path(sys.argv[1])
