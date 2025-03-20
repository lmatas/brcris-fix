python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Crear archivo .env con configuración de base de datos
cat > .env << EOL
DB_HOST=localhost
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=
DB_PORT=5432
EOL

echo "Entorno configurado y archivo .env creado."
