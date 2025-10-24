# ?? Quick Deployment Guide

## Option 1: Azure Portal (Easiest)

1. **Click the Deploy to Azure button** in README.md
2. **Fill in these passwords** (or use your own):

```
Admin Password:       Azure@Patroni2024!
Postgres Password:    PostgreSQL@2024!
Replicator Password:  Replicator@2024!
PgBouncer Admin Pass: PgBouncer@2024!
```

3. **Click "Review + Create"** ? **Create**
4. **Wait 15-20 minutes** for deployment
5. **Done!** ?

---

## Option 2: Azure CLI (Fastest)

```bash
# Create resource group
az group create --name pgpatroni-rg --location germanywestcentral

# Deploy with parameters file
az deployment group create \
  --resource-group pgpatroni-rg \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json

# Or deploy with inline parameters
az deployment group create \
  --resource-group pgpatroni-rg \
  --template-file azuredeploy.json \
  --parameters \
    adminUsername=azureuser \
    adminPassword='Azure@Patroni2024!' \
    postgresPassword='PostgreSQL@2024!' \
    replicatorPassword='Replicator@2024!' \
    pgbouncerAdminPass='PgBouncer@2024!' \
    numberOfNodes=2 \
    diskSku=Premium_LRS
```

---

## Option 3: PowerShell

```powershell
# Create resource group
New-AzResourceGroup -Name pgpatroni-rg -Location germanywestcentral

# Deploy
New-AzResourceGroupDeployment `
  -ResourceGroupName pgpatroni-rg `
  -TemplateFile azuredeploy.json `
  -TemplateParameterFile azuredeploy.parameters.json
```

---

## ?? Post-Deployment

### Get VM Public IPs
```bash
az vm list-ip-addresses \
  --resource-group pgpatroni-rg \
  --output table
```

### SSH to Database VM
```bash
ssh azureuser@<PUBLIC_IP>
# Password: Azure@Patroni2024!
```

### Check Cloud-Init Status
```bash
cloud-init status --long
```

### Check Patroni Cluster
```bash
curl http://localhost:8008/cluster | jq
```

### Connect to PostgreSQL
```bash
# Via PgBouncer (recommended for apps)
PGPASSWORD='PostgreSQL@2024!' psql -h 10.50.1.11 -p 6432 -U postgres -d postgres

# Direct to database (for admin tasks)
PGPASSWORD='PostgreSQL@2024!' psql -h 10.50.1.10 -p 5432 -U postgres -d postgres
```

---

## ?? Configuration Parameters

| Parameter | Default | Options | Description |
|-----------|---------|---------|-------------|
| `numberOfNodes` | `2` | 2, 3 | Number of database nodes |
| `vmSize` | `Standard_D4s_v5` | D2s-D32s, E2s-E16s | VM size |
| `diskSku` | `Premium_LRS` | Premium_LRS, Premium_ZRS, StandardSSD_LRS, StandardSSD_ZRS, UltraSSD_LRS | Disk type |
| `dataDiskSizeGB` | `1024` | 128-32767 | Data disk size |
| `walDiskSizeGB` | `512` | 128-32767 | WAL disk size |
| `enablePublicLB` | `false` | true, false | Enable public load balancer |
| `enablePgBouncerTier` | `true` | true, false | Enable PgBouncer tier |

---

## ?? Change Passwords After Deployment

**IMPORTANT**: For production, change default passwords!

```bash
# SSH to VM
ssh azureuser@<VM_IP>

# Change PostgreSQL passwords
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'NewStrongPassword';"
sudo -u postgres psql -c "ALTER USER replicator WITH PASSWORD 'NewStrongPassword';"

# Update Patroni config
sudo nano /etc/patroni/patroni.yml
# Update password fields

# Restart Patroni
sudo systemctl restart patroni
```

---

## ?? Troubleshooting

### Cloud-init failed?
```bash
cat /var/log/cloud-init-output.log
journalctl -u cloud-init
```

### Patroni not starting?
```bash
journalctl -u patroni -n 50
systemctl status patroni
```

### etcd cluster issues?
```bash
journalctl -u etcd -n 50
curl http://localhost:2379/health
```

---

## ?? Run Tests

```bash
curl -o test.sh https://raw.githubusercontent.com/errorcu/azpatronipostgre/main/scripts/test-deployment.sh
chmod +x test.sh
sudo ./test.sh
```

---

## ?? Monitoring

### Patroni Cluster Status
```bash
curl http://localhost:8008/cluster | jq
```

### PostgreSQL Replication
```bash
PGPASSWORD='PostgreSQL@2024!' psql -h 10.50.1.10 -p 5432 -U postgres \
  -c "SELECT * FROM pg_stat_replication;"
```

### PgBouncer Stats
```bash
PGPASSWORD='PostgreSQL@2024!' psql -h 10.50.1.11 -p 6432 -U postgres -d pgbouncer \
  -c "SHOW POOLS;"
```

---

## ??? Clean Up

```bash
# Delete resource group (deletes everything)
az group delete --name pgpatroni-rg --yes --no-wait
```

---

## ?? Tips

- **2 nodes** = Cheaper, good for dev/test
- **3 nodes** = Production HA, better fault tolerance
- **Premium_LRS** = Best performance
- **Premium_ZRS** = Zone-redundant (best HA)
- Use **PgBouncer** for application connections
- Use **direct DB** for admin/ETL tasks
