import boto3
import pandas as pd
import io
import os


bucket_destino = os.environ.get('BUCKET_DESTINO','')
sns_topic_arn = os.environ.get('SNS_TOPIC_ARN','')
email_list_str = os.environ.get('EMAIL_LIST','')
email_list = email_list_str.split(',')

# SNS
sns_client = boto3.client('sns')

# Cliente S3
s3 = boto3.client('s3')

def lambda_handler(event, context):
    record = event['Records'][0]
    bucket_raw = record['s3']['bucket']['name']
    file_key = record['s3']['object']['key']
    bucket_trusted = bucket_destino

    resultado = {
        "status": "Sucesso",
        "usuario": "gabriel.bduarte@sptech.school",
        "acao": "processamento de dados"
    }

    mensagem_formatada_sucesso = f"""
    Olá! A função Lambda foi executada com sucesso no ETL.
    Detalhes:
    - Status: {resultado['status']}
    - Usuário: {resultado['usuario']}
    - Ação executada: {resultado['acao']}
    Att, seu sistema automatizado
    """

    mensagem_formatada_erro = f"""
    Olá! A função Lambda foi executada com falha no ETL.
    Detalhes:
    - Status: Falha
    - Usuário: {resultado['usuario']}
    - Ação executada: {resultado['acao']}
    Att, seu sistema automatizado
    """

    try:
        s3_response = s3.get_object(Bucket=bucket_raw, Key=file_key)
        file_content = s3_response['Body'].read()

        # Verifica extensão do arquivo
        extension = os.path.splitext(file_key)[1].lower()
        if extension == '.csv':
            df_transform = pd.read_csv(io.BytesIO(file_content))
        elif extension in ['.xlsx', '.xls']:
            df_transform = pd.read_excel(io.BytesIO(file_content))
        else:
            raise ValueError(f"Extensão de arquivo não suportada: {extension}")

        ''' 🔹 Tratamento de dados '''
        df_transform['Created at'] = pd.to_datetime(df_transform['Created at'], errors='coerce')
        df_transform['Nome do solicitante'] = df_transform['Nome do solicitante'].str.title()
        df_transform['Email do solicitante'] = df_transform['Email do solicitante'].str.lower()
        df_transform['Categoria'] = df_transform['Categoria'].str.strip().str.capitalize()

        campos_obrigatorios = ['Categoria', 'Email do solicitante', 'Nome do solicitante', 'Titulo']
        df_transform = df_transform.dropna(subset=campos_obrigatorios)
        for campo in campos_obrigatorios:
            df_transform = df_transform[df_transform[campo].astype(str).str.strip() != '']

        df_transform = df_transform.sort_values(by='Categoria')

        # Sempre salva como CSV
        output_buffer = io.BytesIO()
        df_transform.to_csv(output_buffer, index=False)
        output_buffer.seek(0)

        s3.put_object(Bucket=bucket_trusted, Key=file_key, Body=output_buffer.getvalue())

        print(f"Arquivo {file_key} processado e salvo no bucket {bucket_trusted}")

        for email in email_list:
            sns_client.publish(
                TopicArn=sns_topic_arn,
                Message=f"Arquivo {file_key} processado e salvo no bucket {bucket_trusted}",
                Subject="Arquivo processado",
                MessageAttributes={
                    'email':{
                        'DataType': 'String',
                        'StringValue': email
                    }
                }
        )

    except Exception as e:
        print(f"Erro ao processar o arquivo {file_key}: {str(e)}")

        for email in email_list:
            sns_client.publish(
                TopicArn=sns_topic_arn,
                Message=f"Arquivo {file_key} processado e salvo no bucket {bucket_trusted}",
                Subject="Arquivo processado",
                MessageAttributes={
                    'email':{
                        'DataType': 'String',
                        'StringValue': email
                    }
                }
        )
