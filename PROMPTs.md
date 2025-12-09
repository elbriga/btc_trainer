## GEMINI Prompts to generate the app

I want a new flutter app where it will track de Bitcoin price on a chart, then it will give the user fake money to buy and sell BTC, simulating what could be earned on real life. make the home_screen with the BTC price chart, the current USD balance and buttons to buy and sell BTC. The price will be pooled minutely on this APIs URL: https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd

Now add a transaction history list between the chart and the action buttons showing the amount and the price in USD

Add a button "Total" on the buy/sell dialog to set the total amount to sell

Make the chart zoomed on the total variation, eg.: find the min and the max of the series and those will be the min and the max on the chart