# This script creation was heavily assisted by AI using the script from pc_hardware directory as a base

import json
import plotly.graph_objs as go
from plotly.subplots import make_subplots
import random

# Load product configuration
with open("products.json") as f:
    products = json.load(f)["products"]

# Load price history
with open("price.json") as f:
    price_data = json.load(f)

# Generate distinct colors for each product
def generate_colors(n):
    colors = []
    for i in range(n):
        hue = i * 360 / n
        colors.append(f'hsl({hue}, 80%, 60%)')
    return colors

colors = generate_colors(len(products))

# Create traces for each product dynamically
traces = []
for i, product in enumerate(products):
    component = product["name"]
    if component in price_data and price_data[component]:
        dates = [entry["date"] for entry in price_data[component]]
        prices = [float(entry["price"]) for entry in price_data[component]]
        
        traces.append(
            go.Scatter(
                name=component,
                x=dates,
                y=prices,
                mode='markers+lines',
                marker=dict(color=colors[i], size=8),
                line=dict(width=2),
                showlegend=True,
                hovertemplate="%{y:.2f} R$<extra>" + component + "</extra>"
            )
        )

# Create figure with improved layout
fig = go.Figure(traces)

fig.update_layout(
    yaxis_title="Price (R$)",
    xaxis_title="Date",
    title="GPU Price Trends by Model and Store",
    hovermode="x unified",
    legend=dict(
        orientation="h",
        yanchor="bottom",
        y=1.02,
        xanchor="right",
        x=1,
        font=dict(size=10)
    ),
    margin=dict(l=50, r=50, b=100, t=100, pad=4),
    plot_bgcolor='white',
    height=700
)

# Configure axes
fig.update_xaxes(
    showgrid=True,
    gridwidth=1,
    gridcolor='LightGray',
    tickangle=45
)

fig.update_yaxes(
    showgrid=True,
    gridwidth=1,
    gridcolor='LightGray',
    tickprefix="R$ ",
    tickformat=".2f"
)

# Add range slider
fig.update_layout(
    xaxis=dict(
        rangeselector=dict(
            buttons=list([
                dict(count=7, label="1w", step="day", stepmode="backward"),
                dict(count=1, label="1m", step="month", stepmode="backward"),
                dict(count=6, label="6m", step="month", stepmode="backward"),
                dict(step="all")
            ])
        ),
        rangeslider=dict(visible=True),
        type="date"
    )
)

fig.show()
