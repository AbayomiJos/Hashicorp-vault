**Install gpg**

```
sudo apt update && sudo apt install gpg
```

**Download the signing key to a new keyring**

```
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```

**Verify the key's fingerprint**

```
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
```

**Add the HashiCorp repo**

```
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```

```
sudo apt update
```

**Finally, Install Vault**

```
sudo apt install vault
```

**Check vault installation**

```
vault --version
```

**create a directory for vault**

```
Mkdir -p vault/data
```

**Go into the directory**

```
cd vault/data/
```
vi config.hcl

ui = true
disable_mlock = true

storage "file" {
  path    = "./vault/data"
  node_id = "node1"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

api_addr = "http://0.0.0.0:8200"
cluster_addr = "https://0.0.0.0:8201"


Starting vault server using config.hcl 
$ vault server -config=config.hcl

$ export VAULT_ADDR='http://<public-IP-address:8200'

# Login on the browser to unseal:
  http://<public-IP-address:8200/ui

$ vault login hvs.LaJiKnBivrM44oHTzVIEesNo

Enable default vault engine
$ vault secrets enable -path=my-secret-engine kv

Store secrets in Vault engine
$ vault kv put my-secret-engine/my-secret username=admin password=securepassword

Read stored secrets in Engine
$ vault kv get my-secret-engine/my-secret

# On the github, create a new repository, add vault secrets and github auth in Settings > Secrets > New repository secret, 
then, craete a github actions workflow: <.github/workflows/vault-update.yml>

SCRIPTS:

name: Sync Vault Secrets to GitHub

on:
  push:
    paths:
      - '.github/workflows/vault-update.yml'  # Trigger on workflow file change
  schedule:
    - cron: "* * * * *"  # Trigger every minute for testing (adjust as needed)

jobs:
  sync-vault-secrets:
    runs-on: ubuntu-latest

    env:
      VAULT_ADDR: http://52.90.118.56:8200  # Vault server address

    steps:
      # Step 1: Checkout the repository
      - name: Checkout Repository
        uses: actions/checkout@v2

      # Step 2: Install Vault CLI
      - name: Install Vault CLI
        run: |
          echo "Installing Vault CLI..."
          curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
          sudo apt-add-repository "deb https://apt.releases.hashicorp.com $(lsb_release -cs) main"
          sudo apt-get update && sudo apt-get install -y vault

      # Step 3: Authenticate with Vault
      - name: Login to Vault
        run: |
          echo "Logging into Vault at $VAULT_ADDR"
          vault login ${{ secrets.VAULT_TOKEN }}
        env:
          VAULT_TOKEN: ${{ secrets.VAULT_TOKEN }}

      # Step 4: Verify Vault Connection
      - name: Test Vault Connection
        run: |
          echo "Testing Vault connection at $VAULT_ADDR"
          curl -s $VAULT_ADDR/v1/sys/health || exit 1

      # Step 5: Retrieve and Save Secrets from Vault
      - name: Get Secrets from Vault
        run: |
          echo "Fetching secrets from Vault..."
          SECRET_ENGINE_PATH="my-secret-engine"
          paths=$(vault list -format=json ${SECRET_ENGINE_PATH} | jq -r '.[]')
          secrets_file="secrets.env"
          echo "# Secrets synced from Vault on $(date)" > $secrets_file

          for path in $paths; do
            echo "Fetching secrets from: ${SECRET_ENGINE_PATH}/${path}"
            secret=$(vault kv get -format=json ${SECRET_ENGINE_PATH}/${path} || echo "")
            keys=$(echo $secret | jq -r '.data.data | keys[]' || echo "")
            for key in $keys; do
              value=$(echo $secret | jq -r ".data.data[\"${key}\"]")
              echo "${path}_${key}=${value}" >> $secrets_file
            done
          done

          echo "Generated secrets file:"
          cat $secrets_file

      # Step 6: Commit and Push Secrets to GitHub
      - name: Commit and Push Secrets to GitHub
        run: |
          echo "Committing and pushing secrets to GitHub..."
          git config --global user.name "GitHub Actions"
          git config --global user.email "actions@github.com"
          git add secrets.env

          # Step 1: Check for uncommitted changes and commit them if necessary
          git diff --cached --quiet || git commit -m "Committing uncommitted changes"
          
          # Step 2: Pull the latest changes from the remote repository
          git pull origin main --rebase || true

          # Step 3: Resolve merge conflicts by keeping the local changes
          git checkout --ours secrets.env

          # Step 4: Commit and push the final changes
          if git commit -m "Update Vault secrets"; then
            git push https://x-access-token:${{ secrets.GITHUB_TOKEN }}@github.com/${{ github.repository }} HEAD:main
          else
            echo "No changes to commit."
          fi
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}





