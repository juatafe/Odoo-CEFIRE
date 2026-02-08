

docker compose down

docker compose up -d --build

docker compose restart web

docker compose exec web bash
odoo -d provestalens -u familia
docker compose logs web


docker compose exec -u root web /bin/bash
docker compose build

git status
git add README.md
git commit -m "Modificar url github README.md"
git push origin master


git clone -b 16.0 https://github.com/OCA/account-financial-tools

tar -cvf saldo_favor08082024.gz /home/talens/odoo_dev/dev_addons/saldo_favor
zip -r saldo_favor.zip saldo_favor/

sudo pvs
sudo lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv
df -h

msgfmt -c -v -o /dev/null dev_addons/saldo_favor/i18n/ca.po
sudo apt install gettext


docker exec -it odoo_dev-db-1 psql -U odoo -d provestalens
docker compose restart web && docker compose exec web odoo -u familia -d provestalens

docker compose restart web && docker compose exec web odoo -u event_family_registration -d provestalens
docker compose exec web odoo --no-xmlrpc -u event_family_registration -d provestalens #per a quan no es pot desinstalar(mode prova de fallos)


zip -r familia.zip familia/

docker cp 141c36f787bc:/usr/lib/python3/dist-packages/odoo/addons/event /tmp/event
pscp -r talens@172.29.34.45:/tmp/event H:\Ajuntament\Odoo\eventos

cd dev_addons/familia/
git init
git add .
git commit -m "Primer commit - Añadiendo módulo de gestión de familias"

gh auth login
gh repo create familia --public --source=. --remote=origin --push

#Identificar y detener el proceso que está usando el puerto 995
sudo lsof -i :995

docker stop $(docker ps -aq)
docker network prune -f
docker system prune -a

sudo systemctl list-units --type=service | grep -E 'postfix|dovecot'

#modo manual
docker start -ai odoo_dev-web-1


 1676  https://github.com/juatafe/saldo_favor/tree/main
 1677  git init
 1681  git init
 1682  git branch -m main
 1683  git add .
 1684  git commit -m "Inicialización del módulo Control de Saldo"
 1685  git remote add origin https://github.com/juatafe/saldo_favor.git
 1686  git push -u origin main
 1690  git push -u origin main
 1691  ssh -T git@github.com
 1692  git push -u origin main
 1693  git remote set-url origin git@github.com:juatafe/saldo_favor.git
 1694  git push -u origin main
 1695  git pull origin main
 1696  git config pull.rebase false
 1697  git pull origin main
 1698  git config pull.rebase true
 1699  git pull origin main
 1700  git config pull.ff only
 1701  git pull origin main
 1702  git add LICENSE
 1703  git add README.md
 1704  git rebase --continue
 1705  git commit -m "Resolved merge conflict in LICENSE and README.md"
 1706  git push -u origin main




cd mailu
wget https://setup.mailu.io/2024.06/file/fcdd9ecb-f9f1-4535-b886-7d8b2d92ab5b/docker-compose.yml
wget https://setup.mailu.io/2024.06/file/fcdd9ecb-f9f1-4535-b886-7d8b2d92ab5b/mailu.env
docker compose -p mailu up -d
docker compose -p mailu exec admin flask mailu admin admin provestalens.es newpassword
docker exec -it odoo_dev-admin-1 /bin/sh
flask mailu admin admin provestalens.es newpassword


docker ps | grep smtp
docker compose down
docker ps
docker network prune -f
docker compose up -d



git init
git add .
git commit -m "primer commit"
git remote add origin https://github.com/juatafe/event_family_registration.git
git branch -M main
git pull origin main --rebase
git push origin main

docker compose restart web && docker compose exec web odoo -u payment_with_saldo -d provestalens


docker exec -it odoo_dev-db-1 psql -U odoo -d provestalens
docker compose exec db psql -U odoo -d provestalens
UPDATE pos_session
SET state = 'closed',
    stop_at = now()
WHERE name = 'POS/00006';
UPDATE 1


docker compose exec web bash
rm -rf /var/lib/odoo/.local/share/Odoo/filestore/provestalens
rm -rf /var/lib/odoo/.local/share/Odoo/web/assets
find /mnt/extra-addons -name '*.pyc' -delete
find /mnt/extra-addons -name '__pycache__' -type d -exec rm -r {} +
exit
docker compose restart web && docker compose exec web odoo -u event_family_registration -d provestalens

#windows
python preparar_fallers_importacio.py 'H:\baixades\taula_ficticia_fallers.xlsx'

#linux
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt


source venv/bin/activate   # Entra a l'entorn virtual
python3 preparar_fallers_importacio.py taula_ficticia_fallers.xlsx
deactivate   


cat eliminarUsuari.sql | docker compose exec -T db psql -U odoo -d provestalens


docker compose exec web pip3 install pandas




# 1. Aturar contenidors
docker compose down

# 2. Netejar contenidors antics, xarxes, volums i logs
docker system prune --volumes -f

# 3. Tornar a arrancar serveis
docker compose up -d

# 4. Veure logs en temps real
docker compose logs -f web



# 1. Reiniciar els containers
docker compose restart web

# 2. Tornar a instal·lar forçadament el mòdul
docker compose exec web odoo -i event_family_registration -d provestalens







cd Documentos/apiOdoo/
source odoo-api-env/bin/activate
python3 main.py