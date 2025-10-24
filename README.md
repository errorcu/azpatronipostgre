# Azure Patroni HA PostgreSQL

Production-ready PostgreSQL High Availability cluster on Azure with Patroni, etcd, and PgBouncer.

## 🚀 Deploy to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ferrorcu%2Fazpatronipostgre%2Fmain%2Fazuredeploy.json)

**One-click deployment** - Fill in the required passwords and deploy!

## 🔑 Default Credentials (For Quick Testing)

**⚠️ IMPORTANT**: Change these passwords in production!

**Note**: These passwords are PostgreSQL/Patroni compatible (no `!` character which can cause issues).

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| **Admin Username** | `azureuser` | VM admin username |
| **Admin Password** | `AzurePatroni2024#` | VM admin password |
| **Postgres Password** | `PostgreSQL2024#Strong` | PostgreSQL superuser password |
| **Replicator Password** | `Replicator2024#Secure` | PostgreSQL replication password |
| **PgBouncer Admin User** | `pgbouncer` | PgBouncer admin user |
| **PgBouncer Admin Pass** | `PgBouncer2024#Admin` | PgBouncer admin password |

**Quick Deploy**: Copy these values into Azure Portal when deploying, or use the parameters file:
```bash
az deployment group create \
  --resource-group YourResourceGroup \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json
```

## ✨ What You Get

- **🔄 Automated Deployment** - Click button, fill parameters, deploy!
- **💾 Database Tier** - 2 or 3 Patroni PostgreSQL nodes (configurable)
- **🔁 High Availability** - Automatic failover with Patroni + etcd
- **🌐 Connection Pooling** - PgBouncer tier (optional, enabled by default)
- **⚖️ Load Balancers** - Internal LB for DB (5432) and PgBouncer (6432)
- **🌍 Public Access** - Optional external load balancer
- **💿 Flexible Storage** - Choose disk SKU (Premium_LRS, Premium_ZRS, StandardSSD_LRS, etc.)
- **🏢 Multi-Zone** - Deployment across availability zones
- **🔒 Security** - Password authentication, NSG rules, private network
- **🌐 NAT Gateway** - For outbound internet access (package installations)

## 📋 Deployment Parameters

### Required Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| **adminPassword** | VM admin password (min 12 chars) | `AzurePatroni2024#` |
| **postgresPassword** | PostgreSQL superuser password | `PostgreSQL2024#Strong` |
| **replicatorPassword** | PostgreSQL replication password | `Replicator2024#Secure` |
| **pgbouncerAdminPass** | PgBouncer admin password | `PgBouncer2024#Admin` |

### Configuration Parameters

| Parameter | Options | Default | Description |
|-----------|---------|---------|-------------|
| **region** | 35+ Azure regions | Germany West Central | Deployment region |
| **prefix** | string | pgpatroni | Resource name prefix |
| **adminUsername** | string | azureuser | VM admin username |
| **vmSize** | D2s_v5 - E16s_v5 | Standard_D4s_v5 | Database VM size |
| **numberOfNodes** | 2 or 3 | 2 | Number of database nodes |
| **dataDiskSizeGB** | 128-32767 | 1024 | Data disk size in GB |
| **walDiskSizeGB** | 128-32767 | 512 | WAL disk size in GB |
| **diskSku** | Premium_LRS, Premium_ZRS, StandardSSD_LRS, StandardSSD_ZRS, UltraSSD_LRS | Premium_LRS | Managed disk SKU |
| **enablePublicLB** | true/false | false | Enable public load balancer |
| **enablePgBouncerTier** | true/false | true | Enable PgBouncer tier |
| **pgbouncerDefaultPool** | 10-1000 | 200 | Pool size per database |
| **pgbouncerMaxClientConn** | 100-10000 | 2000 | Max client connections |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│              Azure Cloud                        │
│                                                 │
│  ┌───────────────┐     ┌──────────────────┐   │
│  │ Public LB     │     │ PgBouncer ILB    │   │
│  │ (Optional)    │     │ 10.50.1.11:6432  │   │
│  │ 5432          │     └────────┬─────────┘   │
│  └───────┬───────┘              │             │
│          │         ┌────────────┴─────────┐   │
│          │         │   PgBouncer VMs      │   │
│          │         │   Zone 1, 2          │   │
│          │         └────────┬─────────────┘   │
│          │                  │                 │
│  ┌───────┴──────┐  ┌────────┴──────────┐     │
│  │ Database ILB │  │                   │     │
│  │ 10.50.1.10   │◄─┘                   │     │
│  │ 5432         │                      │     │
│  └───────┬──────┘                      │     │
│          │                             │     │
│  ┌───────┴─────────────────────────┐   │     │
│  │  PostgreSQL + Patroni + etcd    │   │     │
│  │  ┌──────┐  ┌──────┐  ┌──────┐  │   │     │
│  │  │Node 1│  │Node 2│  │Node 3│  │   │     │
│  │  │Zone 1│  │Zone 2│  │Zone 3│  │   │     │
│  │  └───┬──┘  └───┬──┘  └───┬──┘  │   │     │
│  │      │         │         │      │   │     │
│  │  ┌───▼─────────▼─────────▼───┐  │   │     │
│  │  │  Replication + etcd sync  │  │   │     │
│  │  └───────────────────────────┘  │   │     │
│  └─────────────────────────────────┘   │     │
│                                         │     │
│  ┌─────────────────────────────────┐   │     │
│  │  Premium SSD Disks              │   │     │
│  │  Data: 1TB  |  WAL: 512GB       │   │     │
│  └─────────────────────────────────┘   │     │
└─────────────────────────────────────────┘
```

## 🎯 Connection Points

- **Applications** → PgBouncer ILB: `10.50.1.11:6432`
- **Admin/ETL** → Database ILB: `10.50.1.10:5432`
- **External** → Public LB: `<public-ip>:5432` (if enabled)

## 📝 Post-Deployment

### 1. Access VMs

```bash
# SSH to database VM
ssh azureuser@<VM_PUBLIC_IP>
# Password: AzurePatroni2024#

# Check cloud-init status
cloud-init status --long

# Check Patroni cluster
curl http://localhost:8008/cluster | jq
```

### 2. Automated Testing

```bash
# Download and run comprehensive test suite
curl -o test.sh https://raw.githubusercontent.com/errorcu/azpatronipostgre/main/scripts/test-deployment.sh
chmod +x test.sh
sudo ./test.sh
```

The test validates:
- ✅ VM connectivity
- ✅ Patroni cluster health
- ✅ PostgreSQL connections
- ✅ PgBouncer functionality
- ✅ Replication status
- ✅ etcd cluster
- ✅ Load balancer routing
- ✅ Performance benchmarks

### 3. Manual Verification

```bash
# Connect via PgBouncer
PGPASSWORD='PostgreSQL2024#Strong' psql -h 10.50.1.11 -p 6432 -U postgres -d postgres -c "SELECT now();"

# Connect directly to database
PGPASSWORD='PostgreSQL2024#Strong' psql -h 10.50.1.10 -p 5432 -U postgres -d postgres -c "SELECT version();"

# Check Patroni status
curl -s http://10.50.1.4:8008/cluster | jq

# Check etcd cluster
ETCDCTL_API=3 etcdctl --endpoints=http://10.50.1.4:2379,http://10.50.1.5:2379 member list
```

## 🔒 Security

- **Authentication**: Password-based (change default passwords!)
- **Network**: NSG rules limit access to VNet
- **TLS**: Configurable (default: prefer)
- **Firewall**: Only required ports open
- **Safe Passwords**: No problematic special characters (`!` `$` `'` `"` avoided)

## 💡 Best Practices

1. **Change Passwords**: Update all default passwords after deployment
2. **Disk SKU**: Use Premium_LRS or Premium_ZRS for production
3. **VM Size**: Choose based on workload (D4s_v5 recommended minimum)
4. **Node Count**: Use 3 nodes for maximum availability
5. **Monitoring**: Enable Azure Monitor and set up alerts
6. **Backups**: Configure automated backups for data protection

## 🔧 Customization

### Change Node Count (2 or 3)
- **2 nodes**: Zones 1 and 2 (cost-effective)
- **3 nodes**: Zones 1, 2, and 3 (maximum HA)

### Disk SKU Options
- **Premium_LRS**: Best performance, locally redundant
- **Premium_ZRS**: Zone-redundant for HA
- **StandardSSD_LRS**: Cost-effective
- **StandardSSD_ZRS**: Zone-redundant SSD
- **UltraSSD_LRS**: Ultra-high performance (specific regions)

## 📊 Monitoring

```bash
# Patroni cluster status
curl http://<any-db-vm>:8008/cluster

# PgBouncer stats
PGPASSWORD='PostgreSQL2024#Strong' psql -h 10.50.1.11 -p 6432 -U postgres -d pgbouncer -c "SHOW POOLS;"

# PostgreSQL replication
PGPASSWORD='PostgreSQL2024#Strong' psql -h 10.50.1.10 -p 5432 -U postgres -c "SELECT * FROM pg_stat_replication;"
```

## 🆘 Troubleshooting

```bash
# Check services
systemctl status patroni
systemctl status etcd
systemctl status pgbouncer

# View logs
journalctl -u patroni -f
journalctl -u etcd -f
journalctl -u pgbouncer -f

# Cloud-init logs
cat /var/log/cloud-init-output.log
```

## 📚 Documentation

- [Patroni Documentation](https://patroni.readthedocs.io/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PgBouncer Documentation](https://www.pgbouncer.org/)
- [etcd Documentation](https://etcd.io/docs/)

## 📄 License

MIT License - See [LICENSE](LICENSE) file

## 🤝 Contributing

Contributions welcome! Please open an issue or submit a pull request.

## 🎉 Credits

Built with ❤️ for production PostgreSQL on Azure
