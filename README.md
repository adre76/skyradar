# ✈ SkyRadar — Aviões em Tempo Real

App web local que detecta sua **geolocalização**, plota no mapa e exibe
**aviões em tempo real** ao seu redor usando a API gratuita do
[OpenSky Network](https://opensky-network.org/).

---

## 🚀 Como rodar

### 1. Instalar dependências

```bash
pip install flask requests
```

### 2. Iniciar o servidor

```bash
python app.py
```

### 3. Abrir no browser

```
http://localhost:5000
```

Quando o browser perguntar sobre **permissão de localização**, clique em
**Permitir** para que o mapa centralize na sua posição real.  
Caso negue, o app usa São Paulo como fallback.

---

## 🛰 Funcionalidades

| Recurso | Detalhe |
|---------|---------|
| 📍 Geolocalização | Via browser (GPS/IP) |
| ✈ Aviões em tempo real | OpenSky Network — API aberta, sem chave |
| 🗺 Mapa interativo | Leaflet + OpenStreetMap (tema radar escuro) |
| ⚙ Raio configurável | 75 / 150 / 250 / 400 km |
| 🔄 Auto-atualização | 30s / 60s / 2min |
| 🎯 Clique no avião | Popup com callsign, altitude, velocidade, rumo |
| 📋 Lista lateral | Todos os voos ordenados com detalhes |

---

## 📡 Sobre a API OpenSky Network

- **URL:** `https://opensky-network.org/api/states/all`
- **Gratuita**, sem necessidade de cadastro para consultas básicas
- Atualiza a cada ~10 segundos (dados ADS-B globais)
- Limite de rate: ~100 req/hora para usuários anônimos

---

## 📁 Estrutura

```
skyradar/
├── app.py              ← servidor Flask + lógica de busca
├── templates/
│   └── index.html      ← UI completa (mapa + sidebar + controles)
└── README.md
```
