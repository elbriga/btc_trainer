## GEMINI Prompts to generate the app

I want a new flutter app where it will track de Bitcoin price on a chart, then it will give the user fake money to buy and sell BTC, simulating what could be earned on real life. make the home_screen with the BTC price chart, the current USD balance and buttons to buy and sell BTC. The price will be pooled minutely on this APIs URL: https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd

Now add a transaction history list between the chart and the action buttons showing the amount and the price in USD

Add a button "Total" on the buy/sell dialog to set the total amount to sell

Make the chart zoomed on the total variation, eg.: find the min and the max of the series and those will be the min and the max on the chart

Add dots on the chart showing when the transactions were done, a green dot for buying and a red one for selling

Show the min price and max price on the chart

Make now a background activity on the android app that will do the pooling of the BTC price minutely and save the data to the app display. It should do the pooling even when the app isn't running
+
i'm getting this error: W/System.err(20215): android.app.ForegroundServiceStartNotAllowedException: startForegroundService() not allowed due to mAllowStartForeground false: service com.example.btc_trainer/id.flutter.flutter_background_service.BackgroundService
+
getting this error now: E/AndroidRuntime(23866): Process: com.example.btc_trainer, PID: 23866
  E/AndroidRuntime(23866): android.app.RemoteServiceException$CannotPostForegroundServiceNotificationException: Bad notification for startForeground
  E/AndroidRuntime(23866):     at android.app.ActivityThread.throwRemoteServiceException(ActivityThread.java:2102)
+
getting this error now: E/flutter (26089): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: type 'int' is not a subtype of type 'double'
  E/flutter (26089): #0      WalletViewModel._initialize.<anonymous closure> (package:btc_trainer/viewmodels/wallet_viewmodel.dart:41:24)
