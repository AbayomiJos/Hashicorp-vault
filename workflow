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





