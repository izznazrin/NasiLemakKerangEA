//+------------------------------------------------------------------+
//|                                             SimpleMA Crossover EA|
//|                                Copyright 2024, IzzNazrin Sdn Bhd |
//+------------------------------------------------------------------+
double sl, tp;
int ticket;
bool canTrade = true;
bool firstTrade = true;
string cross = "";
datetime lastTradeTime = 0;

// External parameters
extern int MA1_Period = 10;
extern int MA2_Period = 50;
extern int MaxOpenOrders = 4;
extern double SL_Points = 70;
extern double TP_Points = 280;
extern double BreakEvenTrigger = 140;
extern double BreakEvenOffset = 20;
extern int TradeDelayMinutes = 10;
extern double Lots = 0.01;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Count the number of open orders for the current symbol           |
//+------------------------------------------------------------------+
int CountOpenOrders()
  {
   int count = 0;
   for(int i = 0; i < OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderType() <= OP_SELL)
        {
         count++;
        }
     }
   return count;
  }
//+------------------------------------------------------------------+
//| Adjust stop loss to breakeven if conditions are met              |
//+------------------------------------------------------------------+
void AdjustStopLossToBreakEven()
  {
   for(int i = 0; i < OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol())
        {
         double entryPrice = OrderOpenPrice();
         double currentPrice = OrderType() == OP_BUY ? Bid : Ask;
         double breakEvenPrice = OrderType() == OP_BUY ? entryPrice + BreakEvenOffset * Point : entryPrice - BreakEvenOffset * Point;

         if(OrderType() == OP_BUY && currentPrice >= entryPrice + BreakEvenTrigger * Point)
           {
            if(OrderStopLoss() < breakEvenPrice)
              {
               if(OrderModify(OrderTicket(), OrderOpenPrice(), breakEvenPrice, OrderTakeProfit(), 0, Blue))
                 {
                  Print("Adjusted SL to breakeven for buy order at ticket: ", OrderTicket());
                 }
               else
                 {
                  Print("Error in modifying buy order: ", GetLastError());
                 }
              }
           }
         else if(OrderType() == OP_SELL && currentPrice <= entryPrice - BreakEvenTrigger * Point)
           {
            if(OrderStopLoss() > breakEvenPrice)
              {
               if(OrderModify(OrderTicket(), OrderOpenPrice(), breakEvenPrice, OrderTakeProfit(), 0, Blue))
                 {
                  Print("Adjusted SL to breakeven for sell order at ticket: ", OrderTicket());
                 }
               else
                 {
                  Print("Error in modifying sell order: ", GetLastError());
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   double MA1 = iMA(Symbol(), PERIOD_M1, MA1_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double MA2 = iMA(Symbol(), PERIOD_M1, MA2_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   
   int openOrders = CountOpenOrders();

   if(MA1 > MA2)
     {
      if(firstTrade || cross == "buy")
        {
         if(canTrade && openOrders < MaxOpenOrders)
           {
            sl = Ask - SL_Points * Point;
            tp = Ask + TP_Points * Point;
            ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, 3, sl, tp, "Buy order", 0, 0, Green);
            if(ticket > 0)
              {
               lastTradeTime = TimeCurrent();
               canTrade = false;
               cross = "sell";
               firstTrade = false;
              }
           }
        }
     }
   else if(MA1 < MA2)
     {
      if(firstTrade || cross == "sell")
        {
         if(canTrade && openOrders < MaxOpenOrders)
           {
            sl = Bid + SL_Points * Point;
            tp = Bid - TP_Points * Point;
            ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, 3, sl, tp, "Sell order", 0, 0, Red);
            if(ticket > 0)
              {
               lastTradeTime = TimeCurrent();
               canTrade = false;
               cross = "buy";
               firstTrade = false;
              }
           }
        }
     }

   if(!canTrade && (TimeCurrent() - lastTradeTime) >= PeriodSeconds(PERIOD_M1) * TradeDelayMinutes)
     {
      canTrade = true;
     }

   // Adjust stop loss to breakeven if conditions are met
   AdjustStopLossToBreakEven();
  }
//+------------------------------------------------------------------+
