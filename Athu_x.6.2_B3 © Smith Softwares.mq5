//+------------------------------------------------------------------+
#define        p_project      "Athu Robot"
#define        p_version      "Athu_x.6.2_B3"
#define        p_author       "Cesar Smith"
#define        p_company      "Smith Softwares"
#define        p_website      "smithsoftwares.com"
#define        p_summary      ""
//+------------------------------------------------------------------+


#include <Trade\Trade.mqh>

CTrade         trade;
CPositionInfo  myposition;

input int      n_magic     = 12082123;
input int      n_lot       = 10;
input int      n_tp        = 100;
input int      n_sl        = 320;
input int      n_deviation = 30;
input int      n_range_en  = 5;
input int      n_range_pr  = 270;
input int      run_hour    = 9;
input int      run_min     = 1;

int            ope_status  = 0;
string         ope_type    = "Null";
string         ope_detail  = "";

int            fl_9h       = 0;
int            fl_10h      = 0;
int            fl_12h      = 0;
int            fl_17h      = 0;

ulong          n_tk_b_en  = 0;
ulong          n_tk_s_en  = 0;
ulong          n_tk_b_pr  = 0;
ulong          n_tk_s_pr  = 0;

double         log_entry   = 0.0;
double         log_exit    = 0.0;
double         log_pts     = 0.0;
double         log_value   = 0.0;

double         max_en      = 0.0;
double         max_tp      = 0.0;
double         max_sl      = 0.0;
double         max_pr      = 0.0;
double         max_pl      = 0.0;

double         min_en      = 0.0;
double         min_tp      = 0.0;
double         min_sl      = 0.0;
double         min_pr      = 0.0;
double         min_pl      = 0.0;

int            count_tp    = 0;
int            count_sl    = 0;

string         cmp_temp    = "";

double         vl_ask      = 0.0;
double         vl_bid      = 0.0;

int OnInit() {
   trade.SetExpertMagicNumber(n_magic);
   trade.SetDeviationInPoints(n_deviation);
   trade.SetTypeFilling(ORDER_FILLING_RETURN);
   trade.LogLevel(1); 
   trade.SetAsyncMode(false);
   return (INIT_SUCCEEDED);
}

void OnTick() {
   
   if (marketStatus() == 1 && startRun() == 1) {
      int hour = getHour();
         
      if (hour == 9 && fl_9h == 0) {
         fl_9h = 1;
         logStage("1 - Clean variables (09h 10m).");
         resetValues();
         ope_status = 1;
      }
       
      if (hour == 10 && fl_10h == 0) {
         if (ope_status == 1) {
            if (mountPositions(10) == 0) {
               fl_10h = 1;
               ope_status = 2;
               logStage("2 - Lanch Positions (10h).");
               launchBuyOrderPending();
               launchSellOrderPending();
            }
         }
      }
      
      if (ope_status == 2) {
         if (PositionSelectByTicket(n_tk_b_en)) {
            ope_status           = 3;
            ope_type             = "Buy";
            log_entry            = myposition.PriceOpen();
            logStage             ("3 - Buy | "+(string)(int)log_entry+" | Tck => "+(string)n_tk_b_en+".");
            deleteOrderByMagic   ();
            //launchBuyDefenseOrderPending();
         } else if (PositionSelectByTicket(n_tk_s_en)) {
            ope_status           = 3;
            ope_type             = "Sell";
            log_entry            = myposition.PriceOpen();
            logStage             ("3 - Sell | "+(string)(int)log_entry+" | Tck => "+(string)n_tk_s_en+".");
            deleteOrderByMagic   ();
            //launchSellDefenseOrderPending();
         }
      }
      
      if (ope_status == 3) {
         vl_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
         vl_bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         
         if (ope_type == "Buy") {
            
            //if (vl_ask >= (max_en-250) && PositionSelectByTicket(n_tk_b_pr)) {
               //closeOrderByTicket(n_tk_b_pr);
               //launchBuyDefenseOrderPending(); 
            //}
            
            if (vl_bid >= max_tp) { // take profit
               closeOrderByTicket(n_tk_b_en);
               deleteOrderByMagic();
               ope_status = 4;
            }
            
            if (vl_bid <= max_sl) { // stop loss
               closeOrderByTicket(n_tk_b_en);
               //closeOrderByTicket(n_tk_b_pr);
               deleteOrderByMagic();
               ope_status = 4;
            }
            
            
         } else if (ope_type == "Sell") {
            
            //if (vl_bid <= (min_en+250) && PositionSelectByTicket(n_tk_s_pr)) {
               //closeOrderByTicket(n_tk_s_pr);
               //launchSellDefenseOrderPending(); 
            //}
            
            if (vl_ask <= min_tp) { // take profit
               closeOrderByTicket(n_tk_s_en);
               deleteOrderByMagic();
               ope_status = 4;
            }
            
            if (vl_ask >= min_sl) { // stop loss
               closeOrderByTicket(n_tk_s_en);
               //closeOrderByTicket(n_tk_s_pr);
               deleteOrderByMagic();
               ope_status = 4;
            }
            
         }
         
      }
      
      if (hour == 12 && fl_12h == 0) {
         fl_9h = 0;
         fl_10h = 0;
         fl_12h = 1;
      }
      
      if (hour == 17 && fl_17h == 0) {
         if (ope_type == "Buy" && ope_status == 3) {
            closeOrderByTicket(n_tk_b_en);
            ope_status = 4;
         } else if (ope_type == "Sell" && ope_status == 3) {
            closeOrderByTicket(n_tk_s_en);
            ope_status = 4;
         }
         
         if (log_pts > 0) {
            count_tp = count_tp + 1;
         } else if (log_pts < 0) {
            count_sl = count_sl + 1;
         }
         logStage    ("4 - TPs => '"+(string)count_tp+"' | SLs => '"+(string)count_sl+"' .");
         fl_17h = 1;
      }
         
      showOperations();
      
      showData(hour, ope_status, ope_type, 
                  max_tp, max_en, max_pr, max_sl,
                     min_sl, min_pr, min_en, min_tp, 
                        n_tk_b_en, n_tk_b_pr,
                           n_tk_s_en, n_tk_s_pr, 
                              ope_detail);
      
   }
   
}

int marketStatus() {
   if (TerminalInfoInteger(TERMINAL_CONNECTED)) {   
      datetime time[];
      CopyTime(_Symbol, PERIOD_M1, 0, 1, time);
      int secRestBar = ((int)time[0]  - (int)TimeCurrent() + PeriodSeconds(PERIOD_M1));  
      if (secRestBar < 0) { return -1; } else { return 1; }
   } 
   return 0;
}

int startRun() {
   MqlDateTime    timeCurr;
   datetime       curr = TimeCurrent();
   TimeToStruct   (curr, timeCurr);
   
   MqlDateTime    timeOPen;
   timeOPen.year  = timeCurr.year;
   timeOPen.mon   = timeCurr.mon;
   timeOPen.day   = timeCurr.day;
   timeOPen.hour  = run_hour;
   timeOPen.min   = run_min;
   timeOPen.sec   = 00;
   datetime open  = StructToTime(timeOPen);
   
   if (open <= curr) { return 1; } return 0;
}

int getHour() { datetime tm = TimeCurrent(); MqlDateTime stm; TimeToStruct(tm, stm); return (int)stm.hour; }

void resetValues() {
   ope_status = 0;
   ope_type = "N";
   max_en      = 0.0;   max_tp      = 0.0;   max_sl      = 0.0;   max_pr      = 0.0;   max_pl     = 0.0;
   min_en      = 0.0;   min_tp      = 0.0;   min_sl      = 0.0;   min_pr      = 0.0;   min_pl     = 0.0;
   n_tk_b_en   = 0;     n_tk_s_en   = 0;     n_tk_b_pr   = 0;     n_tk_s_pr   = 0;
   log_entry   = 0.0;   log_exit    = 0.0;   log_pts     = 0.0;   log_value   = 0.0;
   fl_12h      = 0;
   fl_17h      = 0;
}

int mountPositions(int hr) {
   MqlRates ratesH1[];
   CopyRates(Symbol(), PERIOD_H1, 0, 2, ratesH1);
   
   MqlDateTime timeTmp;
   datetime temp = TimeCurrent();
   TimeToStruct(temp, timeTmp);
   
   MqlDateTime timeCurr;
   timeCurr.year = timeTmp.year;
   timeCurr.mon = timeTmp.mon;
   timeCurr.day = timeTmp.day;
   timeCurr.hour = hr-1;
   timeCurr.min = 00;
   timeCurr.sec = 00;
   datetime curr = StructToTime(timeCurr);
   
   if (ratesH1[0].time == curr) {
      max_en = ratesH1[0].high + n_range_en;
      max_tp = (ratesH1[0].high + n_range_en) + n_tp;
      max_sl = (ratesH1[0].high + n_range_en) - n_sl;
      max_pr = max_en - n_range_pr;
      
      min_en = ratesH1[0].low - n_range_en;
      min_tp = (ratesH1[0].low - n_range_en) - n_tp;
      min_sl = (ratesH1[0].low - n_range_en) + n_sl;
      min_pr = min_en + n_range_pr;
      return 0;
   } else { return 1; }
}

void launchBuyOrderPending() {
   trade.BuyStop(n_lot, max_en, Symbol(), 0, 0, ORDER_TIME_GTC, 0, p_version);
   if (trade.ResultDeal() != 0) { n_tk_b_en = (int)trade.ResultDeal(); } else { n_tk_b_en = (int)trade.ResultOrder(); }
}

void launchBuyDefenseOrderPending() {
   trade.SellStop(n_lot*4, max_pr, Symbol(), 0, 0, ORDER_TIME_GTC, 0, p_version);
   if (trade.ResultDeal() != 0) { n_tk_b_pr = (int)trade.ResultDeal(); } else { n_tk_b_pr = (int)trade.ResultOrder(); }
}

void launchSellOrderPending() {
   trade.SellStop(n_lot, min_en, Symbol(), 0, 0, ORDER_TIME_GTC, 0, p_version);
   if (trade.ResultDeal() != 0) { n_tk_s_en = (int)trade.ResultDeal(); } else { n_tk_s_en = (int)trade.ResultOrder(); }
}

void launchSellDefenseOrderPending() {
   trade.BuyStop(n_lot*4, min_pr, Symbol(), 0, 0, ORDER_TIME_GTC, 0, p_version);
   if (trade.ResultDeal() != 0) { n_tk_s_pr = (int)trade.ResultDeal(); } else { n_tk_s_pr = (int)trade.ResultOrder(); }
}

void closeOrderByTicket(ulong n_tk_r) {
   trade.PositionClose     (n_tk_r, n_deviation);
   log_exit                = trade.ResultPrice();
   logPosition             ();
}

void logPosition() {
   if      (ope_type == "Buy")  { log_pts = log_exit - log_entry; }
   else if (ope_type == "Sell") { log_pts = log_entry - log_exit; }
   log_value = log_pts * n_lot * 0.20;
   Print(StringFormat("###\n### %s %s Entry => %d | Exit => %d | Pts => %d | Value => %d\n###\n", getSign(), ope_type, (int)log_entry, (int)log_exit, (int)log_pts, (int)log_value));
}

string getSign() {
   datetime tm = TimeCurrent();
   MqlDateTime stm;
   TimeToStruct(tm, stm);
   string d_day = (string)stm.day; string d_mon = (string)stm.mon; string d_yea = (string)stm.year; string d_hou = (string)stm.hour; string d_min = (string)stm.min;
   if (StringLen(d_day) == 1) { d_day = "0"+d_day; } if (StringLen(d_mon) == 1) { d_mon = "0"+d_mon; } if (StringLen(d_hou) == 1) { d_hou = "0"+d_hou; } if (StringLen(d_min) == 1) { d_min = "0"+d_min; }
   return p_project+" - "+d_day+"/"+d_mon+"/"+d_yea+" | "+d_hou+":"+d_min;
}

void logStage(string msg) {
   Print(StringFormat("###\n### %s # %s \n###\n", getSign(), msg));
}

void showOperations() {
   HistorySelect  (0, TimeCurrent());
   uint           total = OrdersTotal();
   ulong          ticket = 0;
   string         type = "";
   
   ope_detail = "---------------------------\n\n ►  Orders:\n";
   for (uint i = 0; i < total; i++) {
      if((ticket = OrderGetTicket(i)) > 0 && OrderGetInteger(ORDER_MAGIC) == n_magic) {
         if       (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP)  { type = "Buy";  }
         else if  (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP) { type = "Sell"; }
         ope_detail = ope_detail + "   " + (string)ticket+" - "+type+" | "+(string)OrderGetInteger(ORDER_MAGIC)+"\n";
      }
   }
   
   ope_detail = ope_detail+"\n ►  Positions:\n";
   total = PositionsTotal();
   
   for (uint i = 0; i < total; i++) {
      if((ticket = PositionGetTicket(i)) > 0 && PositionGetInteger(POSITION_MAGIC) == n_magic) {
         if       (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)  { type = "Buy";  }
         else if  (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) { type = "Sell"; }
         ope_detail = ope_detail + "   " + (string)ticket+" - "+type+" | "+(string)PositionGetInteger(POSITION_MAGIC)+"\n";      
      }
   }
   
   ope_detail = ope_detail+"\n ►  Transactions:\n";
   total = HistoryDealsTotal();
   
   for (uint i = 0; i < total; i++) {
      int closed = 0;
      
      MqlDateTime timeTmp;
      datetime temp = TimeCurrent();
      TimeToStruct(temp, timeTmp);
      
      MqlDateTime timeCurr;
      timeCurr.year = timeTmp.year;
      timeCurr.mon = timeTmp.mon;
      timeCurr.day = timeTmp.day;
      timeCurr.hour = 09;
      timeCurr.min = 00;
      timeCurr.sec = 00;
      datetime curr = StructToTime(timeCurr);
         
      if((ticket = HistoryDealGetTicket(i)) > 0 && HistoryDealGetInteger(ticket, DEAL_MAGIC) == n_magic && curr < HistoryDealGetInteger(ticket, DEAL_TIME)) {
         if       (HistoryDealGetInteger(ticket, DEAL_TYPE) == DEAL_TYPE_BUY)  { type = "Buy";  }
         else if  (HistoryDealGetInteger(ticket, DEAL_TYPE) == DEAL_TYPE_SELL) { type = "Sell"; }
        ope_detail = ope_detail + "   " + (string)ticket + " - " + type + " | " + 
                     (string)HistoryDealGetInteger(ticket, DEAL_MAGIC) + " - " +
                     (string)HistoryDealGetInteger(ticket, DEAL_ORDER) + "\n";
      }
   }
   
}

void showData(int hour_r,
                  int ope_status_r, string ope_type_r,
                        double max_tp_r, double max_en_r, double max_pr_r, double max_sl_r,
                           double min_sl_r, double min_pr_r, double min_en_r, double min_tp_r,
                              ulong n_tk_b_en_r, ulong n_tk_b_pr_r,
                                 ulong n_tk_s_en_r, ulong n_tk_s_pr_r,
                                    string ope_detail_r) {
   Comment(
      StringFormat(
         "\n\n%s  -  %s  |  %d h " +
         "\n\nStatus => %d \nOperation => %s " +
         "\n\n\nMax_tp => %d \n  Max_en => %d \n  Max_pr => %d \nMax_sl => %d" +
         "\n\nMin_sl => %d \n  Min_pr => %d \n  Min_en => %d \nMin_tp => %d" +
         "\n\n\nTicket Buy En => %I64u \nTicket Buy Pr => %I64u" +
         "\n\n\nTicket Sell En => %I64u \nTicket Sell Pr => %I64u" +
         "\n\n%s"
         , p_version, TimeToString(TimeCurrent()), hour_r
         , ope_status_r, ope_type_r
         , (int)max_tp_r, (int)max_en_r, (int)max_pr_r, (int)max_sl_r
         , (int)min_sl_r, (int)min_pr_r, (int)min_en_r, (int)min_tp_r
         , n_tk_b_en_r, n_tk_b_pr_r
         , n_tk_s_en_r, n_tk_s_pr_r
         , ope_detail_r
      )
   );
}

void deleteOrderByMagic() {
   HistorySelect  (0, TimeCurrent());
   uint           total = OrdersTotal();
   ulong          ticket = 0;
   for (uint i = 0; i < total; i++) {
      if((ticket = OrderGetTicket(i)) > 0 && OrderGetInteger(ORDER_MAGIC) == n_magic) {
         trade.OrderDelete(ticket);
         logStage("33 - Delete Order Ticket => '"+(string)ticket+"'.");
      }
   }
}


