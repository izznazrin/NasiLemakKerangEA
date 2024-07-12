//+------------------------------------------------------------------+
//|                                                      LemakKerang |
//|                                Copyright 2024, IzzNazrin Sdn Bhd |
//|                                          http://www.xhamster.com |
//+------------------------------------------------------------------+
double sl, tp;
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
void OnTick()
  {
   double MA10 = iMA(Symbol(), PERIOD_M1, 10, 0, MODE_SMA, PRICE_CLOSE, 0);
   double MA50 = iMA(Symbol(), PERIOD_M1, 50, 0, MODE_SMA, PRICE_CLOSE, 0);
      
   int openOrders = CountOpenOrders();

   if(MA10 > MA50)
     {
      if(firstTrade || cross == "buy")
        {
         if(canTrade && openOrders < 5)
           {
            sl = Ask - 100 * Point;
            tp = Ask + 300 * Point;
            ticket = OrderSend(Symbol(), OP_BUY, 0.01, Ask, 3, sl, tp, "Buy order", 0, 0, Green);
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
   else
      if(MA10 < MA50)
        {
         if(firstTrade || cross == "sell")
           {
            if(canTrade && openOrders < 3)
              {
               sl = Bid + 100 * Point;
               tp = Bid - 300 * Point;
               ticket = OrderSend(Symbol(), OP_SELL, 0.01, Bid, 3, sl, tp, "Sell order", 0, 0, Red);
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

   if(!canTrade && (TimeCurrent() - lastTradeTime) >= PeriodSeconds(PERIOD_M1) * 10)
     {
      canTrade = true;
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
