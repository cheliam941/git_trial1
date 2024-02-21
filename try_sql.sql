select a.trade_date,
           b.book,
           a.appl_id             as appl_id,
           a.posi_type,
           a.investor_id         as type_value,
           concat(a.security_id,'.',a.market) as instrument_id,
           i.instrument_type as instrument_type,
           i.underlying_instrument_id,
           i.contract_unit       as contract_unit,
           a.qty                 as instrument_qty,
           a.qty * contract_unit as underlying_qty,
           1                     as delta,
    --        a.qty * instrument_last_price * delta as delta_cash,
           current_timestamp     as update_time
    from (
             select trade_date,
                    appl_id,
                    'contract'       as     posi_type,
                    self_investor_id as     investor_id,
                    market,
                    security_id,
                    sum(side * current_qty) qty
             from settle_his.tradingbook_contract_his_active_ext
             where trade_date = '{trade_date}'
               and self_account_id in (select accnt_id from settle.cms_account)
               and opposite_investor_id not in (select investor_id
                                                from settle.cms_account
                                                where accnt_name ~ '互换对冲1')
             group by trade_date, appl_id, self_investor_id, market, security_id) a
             left join risk.instrument i on a.market = i.market and a.security_id = i.security_id
             left join booking.contract_account_book b on a.investor_id = b.investor_id
             left join settle.security c on a.market = c.market and a.security_id = c.security_id;








select a.trade_date,
           b.book,
           '对冲交易'                           as appl_id,
           posi_type,
           a.strategy                       as type_value,
           concat(a.security_id,'.',a.market) as instrument_id,
           i.instrument_type                as instrument_type,
           i.underlying_instrument_id,
           i.contract_unit                  as contract_unit,
           a.qty                            as instrument_qty,
           a.qty * contract_unit            as underlying_qty,
           1                                as delta,
           current_timestamp as update_time
    from (
             select to_char(trade_date, 'yyyymmdd') trade_date,
                    'hedge'  as                     posi_type,
                    strategy as                     strategy,
                    market,
                    security_id,
                    sum(side * quantity)            qty
             from booking.swap_hedge_position
             where market not in ('OTC')
               and to_char(trade_date, 'yyyymmdd') = '{trade_date}'
                  group by trade_date, strategy, market, security_id) a
             left join booking.swap_strategy b on a.strategy = b.strategy
             left join risk.instrument i on a.market = i.market and a.security_id = i.security_id;

























-- 各个book的敞口汇总
    select trade_date,
           a.book,
           b.pm,
           b.trading_team,
           b.trading_director,
           b.trader,
           delta_cash,
           long_delta_cash,
           short_delta_cash
    from (
             select a.book,
                    trade_date,
                    sum(delta_cash)                                             delta_cash,
                    sum(case when delta_cash > 0 then delta_cash else 0 end) as long_delta_cash,
                    sum(case when delta_cash < 0 then delta_cash else 0 end) as short_delta_cash
             from (select book, trade_date, underlying_instrument_id, sum(delta_cash) as delta_cash
                   from risk.otc_expo_detail
                   where trade_date = '{trade_date}'
                   group by book, trade_date, underlying_instrument_id) a
             where delta_cash <> 0
             group by trade_date, book) a
             left join booking.book b on a.book = b.book
    where b.pm='张涵' and a.book<>'衍生投资部_场外期权交易台'
    order by a.delta_cash ;










select book,
           underlying_instrument_id,
           sum(underlying_qty)                         as underlying_qty,
           sum(delta_cash)                             as delta_cash,
           json_object_agg(type_value, underlying_qty) as underlying_qty_info
    from (select book,
                 trade_date,
                 concat(posi_type, ':', type_value) as type_value,
                 underlying_instrument_id,
                 sum(delta_cash)                       delta_cash,
                 sum(underlying_qty)                   underlying_qty,
                 sum(instrument_qty)                   instrument_qty
          from risk.otc_expo_detail where trade_date = '{trade_date}'
          group by book, trade_date, concat(posi_type, ':', type_value), underlying_instrument_id) a
    group by book, underlying_instrument_id
    having sum(underlying_qty) <> 0;













-- 各个book在 不同underlying上的敞口，关于 合约端和对冲端的分布情况
    select book,
           underlying_instrument_id,
           sum(underlying_qty)                         as underlying_qty,
           sum(delta_cash)                             as delta_cash,
           json_object_agg(type_value, underlying_qty) as underlying_qty_info
    from (select book,
                 trade_date,
                 concat(posi_type, ':', type_value) as type_value,
                 underlying_instrument_id,
                 sum(delta_cash)                       delta_cash,
                 sum(underlying_qty)                   underlying_qty,
                 sum(instrument_qty)                   instrument_qty
          from risk.otc_expo_detail where trade_date = '{trade_date}'
          group by book, trade_date, concat(posi_type, ':', type_value), underlying_instrument_id) a
    group by book, underlying_instrument_id
    having sum(underlying_qty) <> 0;










    -- 各个book在 不同underlying上的敞口，关于 instrument的分布情况
    select book,
           underlying_instrument_id,
           sum(underlying_qty)                            as underlying_qty,
           sum(delta_cash)                                as delta_cash,
           json_object_agg(instrument_id, instrument_qty) as instrument_qty_info
    from (
             select book,
                    trade_date,
                    underlying_instrument_id,
                    instrument_id,
                    sum(delta_cash)     delta_cash,
                    sum(underlying_qty) underlying_qty,
                    sum(instrument_qty) instrument_qty
             from risk.otc_expo_detail where trade_date = '{trade_date}'
             group by book, trade_date, underlying_instrument_id, instrument_id) a
    group by book, underlying_instrument_id
    having sum(underlying_qty) <> 0;








select a.OrderID, a.CustomerID, a.OrderDate, b.CustomerID, b.CustomerName, b.ContactName, b.Country
from (
        select * from Orders
                 where OrderDate LIKE '%2017%') a
    left join Customers AS b on a.CustomerID = b.CustomerID)
where b.Country = 'Germany'

select *
from Orders as A
             left join Customers as B on A.CustomerID = B.CustomerID
where A.OrderDate LIKE '%2017%' AND B.Country = 'Germany'


select A.product_id
from sales A
left join products B on A.product_id = B.product_id
group by product_id
having sum(A.qty * B.cost) =
       (

select max(AB.money) from
(
select sum(A.qty * B.cost) as money,
       A.product_id
from sales A
left join products B on A.product_id = B.product_id
group by product_id) AB)


select ave(rating) from movies
left join rating on movies.movie_id = rating.movie_id
group by genre