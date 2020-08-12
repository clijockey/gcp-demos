# Google Cloud Function Example with Google Secret Manager

Enable the Google Secret Manager API;

```bash
gcloud services enable secretmanager.googleapis.com cloudfunctions.googleapis.com
```

Now create a new secret

```bash
echo -n "SuperSecretPassword" | \
    gcloud beta secrets create sssssshh \
      --data-file=- \
      --replication-policy automatic
```

NOTE: `--data-file=-` flag allows us to pipe the secret to the gcloud command from the output of the previous command

You can access your secret now via `gcloud` if wanted;

```
gcloud beta secrets versions access 1 --secret="sssssshh"
```

Alow the function to access the secrets;

```bash
gcloud beta secrets add-iam-policy-binding sssssshh \
    --role roles/secretmanager.secretAccessor \
    --member serviceAccount:${PROJECT_ID}@appspot.gserviceaccount.com
```

Now lets depoy our function

```bash
gcloud functions deploy hello_secret \
    --runtime python37 \
    --trigger-http \
    --allow-unauthenticated
```

The target URL can be seen in the output under `httpsTrigger`, either browse to it or `curl` it.