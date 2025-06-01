import json
import requests
import pandas as pd
import boto3
from io import StringIO

PIPEFY_API_URL = "https://api.pipefy.com/graphql"
PIPEFY_TOKEN = "eyJhbGciOiJIUzUxMiJ9.eyJpc3MiOiJQaXBlZnkiLCJpYXQiOjE3NDc1OTAxNzAsImp0aSI6IjQ5OTg2NjFhLWJhMmUtNGM2Zi1hMzgyLWExZGNmOWRkZTM1ZSIsInN1YiI6MzA0NDczNjA1LCJ1c2VyIjp7ImlkIjozMDQ0NzM2MDUsImVtYWlsIjoiZ2FicmllbC5iZHVhcnRlQHNwdGVjaC5zY2hvb2wifX0.RidLt5H80JX7SaRbxWht3lTGmBW81wYiQAs-hPNJ9am_T-r9-oybTeC6ZuxY0JwviOetgqSh4hnlg5MTK_NDyQ"
PIPE_ID = 306351004
S3_BUCKET = os.environ.get('BUCKET_ENTRADA','')
CSV_FILE_NAME = "vaction-poc.csv"

def lambda_handler(event, context):
    query = """
    query {
      allCards(pipeId: %s, first: 100) {
        edges {
          node {
            id
            title
            createdAt
            createdBy {
              name
            }
            current_phase {
              name
            }
            fields {
              name
              value
            }
          }
        }
      }
    }
    """ % PIPE_ID
    headers = {
        "Authorization": f"Bearer {PIPEFY_TOKEN}",
        "Content-Type": "application/json"
    }
    response = requests.post(PIPEFY_API_URL, json={"query": query}, headers=headers)
    if response.status_code != 200:
        raise Exception(f"Erro na requisição ao Pipefy: {response.text}")
    cards = response.json()["data"]["allCards"]["edges"]
    data = []
    for edge in cards:
        node = edge["node"]
        fields = {field["name"]: field["value"] for field in node["fields"]}
        row = {
            "Title": node["title"],
            "Current Phase": node["current_phase"]["name"] if node["current_phase"] else None,
            "Creator": node["createdBy"]["name"] if node["createdBy"] else None,
            "Created at": node["createdAt"],
            "Nome do solicitante": fields.get("Nome do solicitante"),
            "Email do solicitante": fields.get("Email do solicitante"),
            "Categoria": fields.get("Categoria"),
            "Titulo": fields.get("Título"),
            "Descrição": fields.get("Descrição")
        }
        data.append(row)
    df = pd.DataFrame(data)
    # Converter para CSV em memória
    csv_buffer = StringIO()
    df.to_csv(csv_buffer, index=False)
    # Enviar para o S3
    print(f"Arquivo do pipefy {CSV_FILE_NAME} processado e salvo no bucket {S3_BUCKET}")
    s3 = boto3.client("s3")
    s3.put_object(
        Bucket=S3_BUCKET,
        Key=CSV_FILE_NAME,
        Body=csv_buffer.getvalue(),
        ContentType='text/csv'
    )
    return {
        "statusCode": 200,
        "body": json.dumps(f"Arquivo {CSV_FILE_NAME} enviado com sucesso para {S3_BUCKET}!")
    }