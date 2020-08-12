import os
from google.cloud import secretmanager

client = secretmanager.SecretManagerServiceClient()
secret_name = "sssssshh"
project_id = os.environ["GCP_PROJECT"]
resource_name = f"projects/{project_id}/secrets/{secret_name}/versions/latest"
response = client.access_secret_version(resource_name)
secret_string = response.payload.data.decode('UTF-8')

def hello_secret(request):
    return "Dont return your secrets like this in real life :-) - p.s. my password is NOT " + secret_string
