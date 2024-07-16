//+------------------------------------------------------------------+
//|                                                 NasiLemakKerangEA|
//|                                Copyright 2024, IzzNazrin Sdn Bhd |
//+------------------------------------------------------------------+
int MA1_Period = 10;
int MA2_Period = 50;
int MaxOpenOrders = 2;
double SL_Points = 100;
double TP_Points = 300;
double BreakEvenTrigger = 150;
double BreakEvenOffset = 20;
int TradeDelayMinutes = 10;
double Lots = 0.01;

int ticket;
bool canTrade = true;
bool firstTrade = true;
string cross = "";
datetime lastTradeTime = 0;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
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
//|                                                                  |
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
         else
            if(OrderType() == OP_SELL && currentPrice <= entryPrice - BreakEvenTrigger * Point)
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
//|                                                                  |
//+------------------------------------------------------------------+
void SetDelay()
  {
   if(!canTrade && (TimeCurrent() - lastTradeTime) >= PeriodSeconds(PERIOD_M1) * TradeDelayMinutes)
     {
      canTrade = true;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   double MA1 = iMA(Symbol(), PERIOD_M1, MA1_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double MA2 = iMA(Symbol(), PERIOD_M1, MA2_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   int openOrders = CountOpenOrders();

   if(MA1 > MA2)
     {
      if(firstTrade)
        {
         cross = "sell";
         firstTrade = false;
        }
      if(cross == "buy" && canTrade && openOrders < MaxOpenOrders)
        {
         ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, 3, Ask - SL_Points * Point, Ask + TP_Points * Point, "Buy order", 0, 0, Blue);
         if(ticket > 0)
           {
            lastTradeTime = TimeCurrent();
            canTrade = false;
            cross = "sell";
            
           }
        }
     }
   else
      if(MA1 < MA2)
        {
         if(firstTrade)
           {
            cross = "buy";
            firstTrade = false;
           }
         if(cross == "sell" && canTrade && openOrders < MaxOpenOrders)
           {
            ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, 3, Bid + SL_Points * Point, Bid - TP_Points * Point, "Sell order", 0, 0, Red);
            if(ticket > 0)
              {
               lastTradeTime = TimeCurrent();
               canTrade = false;
               cross = "buy";
              }
           }
        }

   SetDelay();
   AdjustStopLossToBreakEven();
  }
//+------------------------------------------------------------------+
