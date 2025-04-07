python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Check if .env file exists, if not, copy the example file
if [ ! -f .env ]; then
    echo "Creando archivo .env a partir de .env.example..."
    cp .env.example .env
fi


echo "Entorno configurado y archivo .env creado."
