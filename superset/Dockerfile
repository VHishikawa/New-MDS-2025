# Comece com a imagem oficial do Superset que você já está usando
FROM apache/superset:4.1.2

# Copie um arquivo de requisitos local para dentro da imagem
COPY requirements-local.txt /app/

# Instale os pacotes definidos no arquivo, forçando a versão correta
# O usuário 'superset' é o usuário não-root que executa a aplicação
USER root
RUN pip install --no-cache-dir -r /app/requirements-local.txt && \
    chown -R superset:superset /app
USER superset