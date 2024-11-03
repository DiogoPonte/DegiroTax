CREATE TABLE [dbo].[degiroTransactions](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Data] [varchar](512) NULL,
	[Hora] [varchar](512) NULL,
	[Produto] [varchar](512) NULL,
	[ISIN] [varchar](512) NULL,
	[Bolsa de] [varchar](512) NULL,
	[Bolsa] [varchar](512) NULL,
	[Quantidade] [int] NULL,
	[Preços] [float] NULL,
	[Ccy Local] [varchar](512) NULL,
	[Valor local] [float] NULL,
	[Ccy1] [varchar](512) NULL,
	[Valor] [float] NULL,
	[Ccy2] [varchar](512) NULL,
	[Taxa de Câmbio] [float] NULL,
	[Custos de transação] [float] NULL,
	[Ccy3] [varchar](512) NULL,
	[Total] [float] NULL,
	[Ccy4] [varchar](512) NULL,
	[ID da Ordem] [varchar](512) NULL
) ON [PRIMARY]
GO