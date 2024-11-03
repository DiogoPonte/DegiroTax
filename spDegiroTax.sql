ALTER PROCEDURE [dbo].[spDegiroTax] 
(
	@startDate date = NULL,
	@endDate date = NULL
)
as
BEGIN


select distinct [Data], [Hora], [Produto], [ISIN], [Bolsa de], [Bolsa], [Quantidade], [Preços], 
		case when [Ccy Local] = 'EUR' then 1
			when [Ccy Local] = pr.RightCcy then 1/[Taxa de Câmbio] 
			when [Ccy Local] = pl.LeftCcy then [Taxa de Câmbio] 
		end * Preços PreçosEUR, 
		[Ccy Local], round([Valor local],2) [Valor local], [Ccy1], round([Valor],2) [Valor], [Ccy2], [Taxa de Câmbio], round([Custos de transação],2) [Custos de transação], [Ccy3], round([Total],2) [Total], [Ccy4], [ID da Ordem]

into #degiroTransactions
from  [dbo].[degiroTransactions] d
left join ccyPairs pl on d.[Ccy Local] = pl.LeftCcy 
left join ccyPairs pr on d.[Ccy Local] = pr.RightCcy 


select [Data] ,[Hora] ,[Produto] ,[ISIN] ,[Bolsa de] ,[Bolsa] ,sum([Quantidade]) Quantidade
 ,ROUND(PreçosEUR,4) PreçosEUR ,[Ccy Local] ,sum([Valor local]) [Valor local] ,[Ccy1]  ,sum([Valor]) [Valor]
 ,[Ccy2] ,[Taxa de Câmbio] ,sum([Custos de transação]) [Custos de transação] ,[Ccy3]
 ,sum([Total]) [Total] ,[Ccy4] ,[ID da Ordem]
into #aggregate


from #degiroTransactions d
where d.ISIN not in (select ISIN from retiredISIN)

group by [Data] ,[Hora] ,[Produto] ,[ISIN] ,[Bolsa de] ,[Bolsa]
 ,PreçosEUR,[Ccy Local] ,[Ccy1] ,[Ccy2] ,[Taxa de Câmbio] 
 ,[Ccy3] ,[Ccy4] ,[ID da Ordem]
order by Data desc


;with 
buy_cte(Produto, ISIN, Data, Preços, Fees, trans_rn) as (
    select Produto, ISIN, Data, case when [Bolsa de] = 'LFF' then ABS(Valor/Quantidade) else PreçosEUR end, [Custos de transação]/abs(Quantidade),
      row_number() over (partition by ISIN order by Data)
    from #aggregate s
    cross apply dbo.fnTally(1, s.Quantidade) fn
    where Quantidade > 0),
sell_cte(Produto, ISIN, Data, Preços, Fees, trans_rn) as (
    select Produto, ISIN, Data, case when [Bolsa de] = 'LFF' then ABS(Valor/Quantidade) else PreçosEUR end, [Custos de transação]/abs(Quantidade),
      row_number() over (partition by ISIN order by Data)
    from #aggregate s
    cross apply dbo.fnTally(1, -s.Quantidade) fn
    where Quantidade < 0)

select s.Produto, s.ISIN, s.Data DataVenda, b.Data DataCompra, count(*) Quantidade,
    cast(sum(s.Preços) as decimal(14,2)) ValorVenda,
  cast(sum(b.Preços) as decimal(14,2)) ValorCompra,  
  cast(sum(s.Preços-b.Preços) as decimal(14,2)) Delta, 
  abs(cast(sum(s.Fees) + sum(b.Fees) as decimal(14,2))) Comissões
  
from buy_cte b
     join sell_cte s on b.ISIN=s.ISIN
     and b.trans_rn=s.trans_rn
     and b.Data<=s.Data
where s.Data >= coalesce(@startDate,s.Data) and s.Data <= coalesce(@endDate,s.Data)
group by s.Produto, s.ISIN, s.Data, b.Data--, s.Fees, b.Fees
order by s.Data desc, b.Data desc;


drop table #degiroTransactions
drop table #aggregate


END