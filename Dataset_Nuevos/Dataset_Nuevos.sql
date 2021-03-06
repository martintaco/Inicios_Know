 /*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.6020)
    Source Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2017
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/

--USE [DATAMARTCOMCHILE]
--GO
--/****** Object:  StoredProcedure [dbo].[pTG_ForecastModel_AllCategory_1]    Script Date: 15/08/2018 11:39:50 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
--ALTER PROCEDURE [dbo].[pTG_ForecastModel_AllCategory_1]
--(
--@flaglog int = 0
--)
--as
--begin
/*
exec pTG_ForecastModel_AllCategory_1 1
*/

/*CORRRER DESDE AQUI*/
	declare @flaglog int 
	set @flaglog = 1


	/* Set Default Value logs  */ 
	declare @m_time datetime,  
		@item int
	  
	set @m_time  = GETDATE()  
	set @item = 1  

	if @flaglog = 0
		SET NOCOUNT ON

	/*
	Declaracion de variables:
	*/

	DECLARE @AnioCampanaIni CHAR(6)
	DECLARE @AnioCampanaFin CHAR(6)
	DECLARE @AnioCampanaIniFuturo CHAR(6)
	DECLARE @AnioCampanaFinFuturo CHAR(6)
	DECLARE @CodPais CHAR(4)
	DECLARE @FlagTest INT
	DECLARE @Tb_DesCategoria table (DesCategoria varchar(100) )
	DECLARE @DesCategoria_all VARCHAR(500)
	

	/*
	Setear variables de procedimiento
	*/
	SET @AnioCampanaIni = (select StringValue from bddm01.DATAMARTANALITICO.dbo.Forecast_Parameters where DescParameter = 'ANIOCAMPANAINI')
	SET @AnioCampanaFin = (select StringValue from bddm01.DATAMARTANALITICO.dbo.Forecast_Parameters where DescParameter = 'ANIOCAMPANAFIN')
	SET @AnioCampanaIniFuturo = (select StringValue from bddm01.DATAMARTANALITICO.dbo.Forecast_Parameters where DescParameter = 'ANIOCAMPANAINIFUTURO')
	SET @AnioCampanaFinFuturo = (select StringValue from bddm01.DATAMARTANALITICO.dbo.Forecast_Parameters where DescParameter = 'ANIOCAMPANAFINFUTURO')
	SET @DesCategoria_all = (select StringValue from bddm01.DATAMARTANALITICO.dbo.Forecast_Parameters where DescParameter = 'CAT_ALL')

	/* Inicio de Categorias*/
	insert into @Tb_DesCategoria select [name] from dbo.splitstring(@DesCategoria_all,',')

	/* Inicio de Proceso */
	if (@FlagLog = 1) print 'Inicio de Proceso: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1  

	/*
		Los códigos de país de SICC de El Salvador y Guatemala no tienen un formato estandar
	*/

	if (@FlagLog = 1) print 'Pais Proceso: ' + @CodPais + ' ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  

	SELECT @CodPais = (select max(left(Sociedad,2)) FROM DPais) 

	/*
		Información base del input
		Tipos de Ofertas validos
	*/
	IF OBJECT_ID('tempdb..#ListaTO') is not null
	DROP TABLE #ListaTO

	select CodTipoOferta, Dataset, Modo, Tactica, FlagSet
	into #ListaTO
	from bddm01.DATAMARTANALITICO.dbo.Forecasting_TipoOferta_QA

	/*
		Precio Normal
		Considerar solo los productos CUC que tienen estimados
	*/
	if (@FlagLog = 1) print 'create #TMP_Estimados: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1  

	IF OBJECT_ID('tempdb..#TMP_Estimados') is not null
	DROP TABLE #TMP_Estimados

	SELECT A.AnioCampana, B.CodCUC, B.CodProductoGenericoI, c.CodTipoOferta,
		SUM(EstUUVendidas) AS NroEstimados, 
		MAX(Case when @CodPais = 'BO' then isnull(PrecioNormalDol,0) else isnull(PrecioNormalMN,0) end) AS PrecioNormalMN  
	INTO #TMP_Estimados
	FROM FVTAPROCAMMES A 
	INNER JOIN DPRODUCTO B ON A.PKProducto = B.PKProducto
	INNER JOIN DTIPOOFERTA C ON A.PKTipoOferta = c.PKTipoOferta
	WHERE A.AnioCampana = A.AnioCampanaRef
	AND AnioCampana BETWEEN @AnioCampanaIni AND @AnioCampanaFinFuturo
	AND DESCATEGORIA in (select DesCategoria from @Tb_DesCategoria)
	GROUP BY A.AnioCampana, B.CodCUC, B.CodProductoGenericoI, c.CodTipoOferta

	/*
		Información base del input
		Campañas cerradas: Solo productos que han facturado en la forma de venta catálogo, productos cosméticos y algunos tipos de oferta
	*/
	IF OBJECT_ID('tempdb..#BASE') is not null
	DROP TABLE #BASE

	--CASE WHEN CodTipoOferta IN ('007','008','011','012','013','014','015','017','018','019','033','036','039','043','044','106','114','116') THEN 1 ---,'010'
	--ELSE 0 END AS FlagCatalogo,
	--CASE WHEN CodTipoOferta IN ('003','009','029','035','038','047','048','049','060','123') THEN 1 ELSE 0 END AS FlagRevista, ---,'064','108','115'
	CREATE TABLE #BASE
	(
		AnioCampana char(6),
		CodCUC varchar(20), 
		PKProducto int, 
		DesMarca varchar(20), 
		CodCategoria varchar(50), 
		DesCategoria varchar(50), 
		CodTipoOferta varchar(5), 
		PKTipoOferta int,
		FlagCatalogo int,
		FlagRevista int,
		RealUUVendidas int,
		RealUUFaltantes int,
		FlagReal int,
		PrecioNormalMN Float
	)

	IF @CodPais <> 'PE'
		INSERT INTO #BASE
		SELECT 
			A.AnioCampana, 
			B.CodCUC, A.PKProducto, B.DesMarca, B.CodCategoria, B.DesCategoria, 
			c.CodTipoOferta, 
			A.PKTipoOferta, -- 0 AS FlagNoConsiderar,
			CASE WHEN D.Modo = 'Catálogo' THEN 1 ELSE 0 END AS FlagCatalogo,
			CASE WHEN D.Modo = 'Revista' THEN 1 ELSE 0 END AS FlagRevista, 
			SUM(RealUUVendidas) AS RealUUVendidas, 
			SUM(RealUUFaltantes) AS RealUUFaltantes, 
			1 AS FlagReal, 
			CONVERT(FLOAT, 0) AS PrecioNormalMN

		FROM FVTAPROEBECAMC01 A 
		INNER JOIN DPRODUCTO B ON A.PKPRODUCTO = B.PKPRODUCTO 
		INNER JOIN DTIPOOFERTA C ON A.PKTipoOferta = C.PKTipoOferta
		INNER JOIN #ListaTO D ON c.CodTipoOferta = d.CodTipoOferta
		WHERE A.ANIOCAMPANA BETWEEN @AnioCampanaIni AND @AnioCampanaFin
		AND A.ANIOCAMPANA = A.ANIOCAMPANAREF
		AND C.CodTipoProfit = '01' --Forma de Venta Catálogo
		AND DesUnidadNegocio IN ('COSMETICOS')
		AND D.Dataset = 1
		AND DESCATEGORIA in (select DesCategoria from @Tb_DesCategoria)
		GROUP BY A.ANIOCAMPANA, B.CODCUC, A.PKProducto, B.DesMarca, B.CodCategoria, B.DesCategoria, C.CodTipoOferta, D.Modo, A.PKTipoOferta
	ELSE
		INSERT INTO #BASE
		SELECT 
			A.AnioCampana, 
			B.CodCUC, A.PKProducto, B.DesMarca, B.CodCategoria, B.DesCategoria, 
			c.CodTipoOferta, 
			A.PKTipoOferta, -- 0 AS FlagNoConsiderar,
			CASE WHEN D.Modo = 'Catálogo' THEN 1 ELSE 0 END AS FlagCatalogo,
			CASE WHEN D.Modo = 'Revista' THEN 1 ELSE 0 END AS FlagRevista, 
			SUM(RealUUVendidas) AS RealUUVendidas, 
			SUM(RealUUFaltantes) AS RealUUFaltantes, 
			1 AS FlagReal, 
			CONVERT(FLOAT, 0) AS PrecioNormalMN

		FROM FVTAPROEBECAMDIGTRAC01_VIEW A 
		INNER JOIN DPRODUCTO B ON A.PKPRODUCTO = B.PKPRODUCTO 
		INNER JOIN DTIPOOFERTA C ON A.PKTipoOferta = C.PKTipoOferta
		INNER JOIN #ListaTO D ON c.CodTipoOferta = d.CodTipoOferta
		WHERE A.ANIOCAMPANA BETWEEN @AnioCampanaIni AND @AnioCampanaFin
		AND A.ANIOCAMPANA = A.ANIOCAMPANAREF
		AND C.CodTipoProfit = '01' --Forma de Venta Catálogo
		AND DesUnidadNegocio IN ('COSMETICOS')
		AND D.Dataset = 1
		AND DESCATEGORIA in (select DesCategoria from @Tb_DesCategoria)
		GROUP BY A.ANIOCAMPANA, B.CODCUC, A.PKProducto, B.DesMarca, B.CodCategoria, B.DesCategoria, C.CodTipoOferta, D.Modo, A.PKTipoOferta

	if (@FlagLog = 1) print 'Create a #BASE: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1  

	/*
		Campañas abiertas: todas las tácticas que han sido ingresadas en Planit y el sistema comercial
	*/ 
	INSERT INTO #BASE
	SELECT 
		A.AnioCampana, 
		B.CodCUC, A.PKProducto, DesMarca, CodCategoria, DesCategoria, 
		C.CodTipoOferta, 
		A.PkTipoOferta, -- 0 AS FlagNoConsiderar,
		CASE WHEN D.Modo = 'Catálogo' THEN 1 ELSE 0 END AS FlagCatalogo,
		CASE WHEN D.Modo = 'Revista' THEN 1 ELSE 0 END AS FlagRevista, 
		0 AS RealUUVendidas, 
		0 AS RealUUFaltantes, 
		0 AS FlagReal, 
		CONVERT(FLOAT, 0) AS PrecioNormalMN
	FROM DMATRIZCAMPANA A 
	INNER JOIN DPRODUCTO B ON A.PKProducto = B.PKProducto
	INNER JOIN DTIPOOFERTA C ON A.PKTipoOferta = C.PKTipoOferta
	INNER JOIN #ListaTO D ON c.CodTipoOferta = d.CodTipoOferta
	WHERE A.ANIOCAMPANA BETWEEN @AnioCampanaIniFuturo AND @AnioCampanaFinFuturo 
	AND CodTipoProfit = '01'
	AND D.Dataset = 1
	AND b.DESCATEGORIA in (select DesCategoria from @Tb_DesCategoria)

	if (@FlagLog = 1) print 'Insert a future campaing: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1  

	delete A
	FROM #BASE A
	INNER JOIN DPRODUCTO B ON A.PKPRODUCTO = B.PKPRODUCTO
	INNER JOIN #TMP_Estimados Est 
		on a.AnioCampana = Est.AnioCampana 
		and a.CodCUC = Est.CodCUC
		and b.CodProductoGenericoI= Est.CodProductoGenericoI 
		and a.CodTipoOferta = Est.CodTipoOferta
	where Est.NroEstimados =0


	--if (@FlagLog = 1) print 'create #TMP_Estimados: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	--select @m_time  = GETDATE(), @item = @item+1  

	--Precio Oferta Dolares
	--Considerar solo los productos CUC que tienen estimados
	IF OBJECT_ID('tempdb..#TMP_DOLAR') is not null
	DROP TABLE #TMP_DOLAR

	SELECT A.AnioCampana, CodCUC,PKTipoOferta,max( isnull(PrecioOfertaDol,0) ) as PrecioOfertaDol  
	INTO #TMP_DOLAR
	FROM FVTAPROCAMMES A  
	INNER JOIN DPRODUCTO B ON A.PKProducto = B.PKProducto
	WHERE A.AnioCampana = A.AnioCampanaRef
	AND AnioCampana BETWEEN @AnioCampanaIni AND @AnioCampanaFinFuturo
	AND DESCATEGORIA in (select DesCategoria from @Tb_DesCategoria)
	GROUP BY A.AnioCampana, CodCUC,PKTipoOferta

	if (@FlagLog = 1) print 'create #TMP_DOLAR: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1  

	--/*Si un  CUC no tiene unidades estimadas se debe eliminar*/
	--UPDATE #BASE
	--SET FlagNoConsiderar = 1
	--FROM #BASE A INNER JOIN #TMP_estimados B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	--WHERE NroEstimados = 0 

	--DELETE FROM #BASE WHERE FlagNoConsiderar = 1

	if (@FlagLog = 1) print 'UPDATE #BASE and Delete: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1  

	--/*Se actualiza el precio normal de cada CUC*/
	UPDATE #BASE
	SET PrecioNormalMN = Est.PRECIONORMALMN
	FROM #BASE A 
	INNER JOIN #TMP_Estimados Est
		ON a.AnioCampana = Est.AnioCampana 
		and a.CodCUC = Est.CodCUC
		and a.CodTipoOferta = Est.CodTipoOferta
	where Est.NroEstimados >0

	if (@FlagLog = 1) print 'Se actualiza el precio normal de cada CUC: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1  

	/*De la matriz de facturación se traen las variables de argumentación y el precio Oferta 
	Se debe tomar en cuenta lo siguiente para campañas cerradas:
	Forma de Venta: Catálogo
	La táctica debe tener registrada la ubicación.
	La táctica debe estar diagramada solo en la revista o en los catálogos
	El código de Venta debe ser diferente a 00000, este es un código dummy de tácticas que llegan a Sicc desde Planit, pero que no se llegan a activar
	El precio de oferta del producto debe ser mayor a 0
	
	*/

	declare @TDesTipoCatalogo table (DesTipoCatalogo varchar(50))
	insert into @TDesTipoCatalogo 
	select [name] as DesTipoCatalogo from dbo.splitstring(
	(select StringValue from BDDM01.DATAMARTANALITICO.dbo.Forecast_Parameters
	where DescParameter = 'TIPOCATALOGO_ALL'),',')

	if (@FlagLog = 1) print '@TDesTipoCatalogoC: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	
	IF OBJECT_ID('tempdb..#TMP_DMATRIZCAMPANA_PRODGENERICO') is not null
	DROP TABLE #TMP_DMATRIZCAMPANA_PRODGENERICO

	SELECT 
		AnioCampana, C.CODCUC, c.CodProductoGenericoI, A.PKTipoOferta, B.CodTipoOferta, DesUbicacionCatalogo, DesLadoPag, DesTipoCatalogo,
		ISNULL(
			CONVERT(FLOAT,
				RIGHT(
					RTRIM(
						REPLACE(
							REPLACE( isnull(DesExposicion,''),'SIN EXPOSICION','')
						, '%', '')
					)
			, 4)
		),0) /100 * NroPaginas AS Exposicion, 
		NroPaginas, 
		MAX( isnull(FotoProducto,'')) AS FotoProducto, 
		MAX( isnull(FotoModelo,'')) AS FotoModelo, 
		MAX( isnull(FlagDiscover,'')) AS FlagDiscover, 
		PaginaCatalogo,
		CONVERT(FLOAT, 0) AS PrecioOferta, 
		1 AS Registros, 
		1 as Eliminar  
	into #TMP_DMATRIZCAMPANA_PRODGENERICO
	FROM DMATRIZCAMPANA A 
	INNER JOIN DTIPOOFERTA B ON A.PKTIPOOFERTA = B.PKTIPOOFERTA
	INNER JOIN DPRODUCTO C ON A.PKPRODUCTO = C.PKPRODUCTO
	WHERE AnioCampana BETWEEN @AnioCampanaIni AND @AnioCampanaFin
	AND CODTIPOPROFIT = '01'
	AND DesUbicacionCatalogo IS NOT NULL 
	AND CODVENTA <> '00000'
	AND DesTipoCatalogo IN (select vp.DesTipoCatalogo from @TDesTipoCatalogo vp)
	GROUP BY AnioCampana, C.CODCUC, c.CodProductoGenericoI, A.PKTipoOferta, B.CodTipoOferta, DesUbicacionCatalogo, DesLadoPag, DesTipoCatalogo, DesExposicion, 
	NroPaginas, PaginaCatalogo
	UNION
	/*Campañas abiertas:
	Forma de Venta: Catálogo
	La táctica debe estar diagramada solo en la revista o en los catálogos
	*/
	SELECT AnioCampana, C.CODCUC, c.CodProductoGenericoI, A.PKTipoOferta, B.CodTipoOferta, DesUbicacionCatalogo, DesLadoPag, DesTipoCatalogo,
	ISNULL(CONVERT(FLOAT,RIGHT(RTRIM(REPLACE(REPLACE(DesExposicion,'SIN EXPOSICION',''), '%', '')), 4)),0)/100 * NroPaginas AS Exposicion, 
	NroPaginas, MAX(FotoProducto) AS FotoProducto, MAX(FotoModelo) AS FotoModelo, MAX(FlagDiscover) AS FlagDiscover, PaginaCatalogo,
	round(MIN(PrecioOferta),2,1) AS PrecioOferta, 1 AS Registros, 1 as Eliminar 
	FROM DMATRIZCAMPANA A 
	INNER JOIN DTIPOOFERTA B ON A.PKTIPOOFERTA = B.PKTIPOOFERTA
	INNER JOIN DPRODUCTO C ON A.PKPRODUCTO = C.PKPRODUCTO
	WHERE AnioCampana BETWEEN @AnioCampanaIniFuturo AND @AnioCampanaFinFuturo
	AND CODTIPOPROFIT = '01'
--	AND DesTipoCatalogo IN ('REVISTA BELCORP', 'CATALOGO CYZONE', 'CATALOGO EBEL/LBEL', 'CATALOGO ESIKA')
	AND DesTipoCatalogo IN (select vp.DesTipoCatalogo from @TDesTipoCatalogo vp)
	GROUP BY A.AnioCampana, C.CODCUC, c.CodProductoGenericoI, A.PKTipoOferta, B.CodTipoOferta, DesUbicacionCatalogo, DesLadoPag, DesTipoCatalogo, DesExposicion, 
	NroPaginas, PaginaCatalogo

	if (@FlagLog = 1) print 'create #TMP_DMATRIZCAMPANA: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	IF OBJECT_ID('tempdb..#TMP_DMATRIZCAMPANA') is not null
	DROP TABLE #TMP_DMATRIZCAMPANA

	SELECT
		AnioCampana, 
		CODCUC,  
		PKTipoOferta, CodTipoOferta, 
		DesUbicacionCatalogo, DesLadoPag, DesTipoCatalogo,
		SUM(ISNULL(Exposicion,0)) as Exposicion, -- 
		NroPaginas, 
		Max(FotoProducto) AS FotoProducto, 
		Max(FotoModelo) AS FotoModelo, 
		Max(FlagDiscover) AS FlagDiscover, 
		PaginaCatalogo,
		round(Min(PrecioOferta),2,1) AS PrecioOferta, 
		Max(Registros) as Registros, 
		Max(Eliminar) as Eliminar
	INTO #TMP_DMATRIZCAMPANA 
	FROM #TMP_DMATRIZCAMPANA_PRODGENERICO
	GROUP BY AnioCampana, CODCUC, PKTipoOferta, CodTipoOferta, DesUbicacionCatalogo, DesLadoPag, DesTipoCatalogo,
	NroPaginas, PaginaCatalogo

	/*Se actualiza el precio de Oferta*/
	IF OBJECT_ID('tempdb..#TMP_PRECIOOFERTA') is not null
	DROP TABLE #TMP_PRECIOOFERTA

	SELECT A.AnioCampana, C.DesCategoria, C.CODCUC, A.PKTipoOferta, B.CodTipoOferta, MIN(PrecioOferta) AS PrecioOferta 
	INTO #TMP_PRECIOOFERTA
	FROM DMATRIZCAMPANA A 
	INNER JOIN DTIPOOFERTA B ON A.PKTIPOOFERTA = B.PKTIPOOFERTA
	INNER JOIN DPRODUCTO C ON A.PKPRODUCTO = C.PKPRODUCTO
	WHERE AnioCampana BETWEEN @AnioCampanaIni AND @AnioCampanaFin
	AND CODTIPOPROFIT = '01'
	AND CODVENTA <> '00000'
	--AND DesTipoCatalogo IN ('REVISTA BELCORP', 'CATALOGO CYZONE', 'CATALOGO EBEL/LBEL', 'CATALOGO ESIKA')
	AND DesTipoCatalogo IN (select vp.DesTipoCatalogo from @TDesTipoCatalogo vp)
	AND PrecioOferta > 0 
	GROUP BY A.AnioCampana, C.DesCategoria, C.CODCUC, A.PKTipoOferta, B.CodTipoOferta
	
	if (@FlagLog = 1) print 'create #TMP_PRECIOOFERTA: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #TMP_DMATRIZCAMPANA
	SET PrecioOferta = B.PrecioOferta
	FROM #TMP_DMATRIZCAMPANA A INNER JOIN #TMP_PRECIOOFERTA B ON A.ANIOCAMPANA = B.ANIOCAMPANA AND A.CodCUC = B.CodCUC AND A.CodTipoOferta = B.CodTipoOferta

	if (@FlagLog = 1) print 'update #TMP_DMATRIZCAMPANA: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	DELETE #TMP_DMATRIZCAMPANA WHERE PrecioOferta = 0 
	/*Se eliminan las tácticas de la revista que están ubicadas en la página 0 o ubicadas en una página mayor a 100, porque normalmente son reacciones*/
	DELETE FROM #TMP_DMATRIZCAMPANA
	WHERE DesTipoCatalogo IN ('REVISTA BELCORP') AND (ISNULL(PaginaCatalogo,0) = 0 OR  ISNULL(PaginaCatalogo,0)>=100)

	if (@FlagLog = 1) print 'DELETE #TMP_DMATRIZCAMPANA: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	/*Agrupamos por producto - tipo de oferta*/
	IF OBJECT_ID('tempdb..#TMP_DMATRIZCAMPANA1') is not null
	DROP TABLE #TMP_DMATRIZCAMPANA1

	SELECT AnioCampana, CodCUC, PKTipoOferta, MIN(PrecioOferta) AS PrecioOferta, 
	SUM(ISNULL(Exposicion,0)) AS Exposicion, SUM(ISNULL(NroPaginas,0)) AS NroPaginas 
	INTO #TMP_DMATRIZCAMPANA1
	FROM #TMP_DMATRIZCAMPANA
	GROUP BY AnioCampana, CodCUC, PKTipoOferta  

	if (@FlagLog = 1) print 'create #TMP_DMATRIZCAMPANA1: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	/*Agrupamos por CUC - Tipo de Oferta para totalizar las unidades vendidas y las unidades faltantes*/
	IF OBJECT_ID('tempdb..#BASE_1') is not null
	DROP TABLE #BASE_1

	SELECT ANIOCAMPANA, CODCUC, DesMarca, CodCategoria, DesCategoria, CodTipoOferta, PKTipoOferta, FlagCatalogo, FlagRevista, 
	SUM(RealUUVendidas) as RealUUVendidas, SUM(RealUUFaltantes)RealUUFaltantes, FlagReal, CONVERT(FLOAT,0) AS PrecioOferta, 
	CONVERT(FLOAT,0) AS Exposicion, AVG(PrecioNormalMN) AS PrecioNormalMN, 0 AS NroPaginas, CONVERT(FLOAT,0) AS Descuento, 0 AS NroPaginasOriginal, 
	CONVERT(FLOAT,0) AS ExposicionOriginal, 0 AS FlagDiagramado
	INTO #BASE_1
	FROM #BASE 
	GROUP BY ANIOCAMPANA, CODCUC, DesMarca, CodCategoria, DesCategoria, CodTipoOferta, PKTipoOferta, FlagCatalogo, FlagRevista, FlagReal
	
	if (@FlagLog = 1) print 'create #BASE_1: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #TMP_DMATRIZCAMPANA1
	SET PrecioOferta = 0 
	WHERE @CodPais = 'BO'
	
	if (@FlagLog = 1) print 'update #TMP_DMATRIZCAMPANA1 Precio= 0: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #TMP_DMATRIZCAMPANA1
	SET PrecioOferta = round(B.PrecioOfertaDol,2,1)
	FROM #TMP_DMATRIZCAMPANA1 A INNER JOIN #TMP_DOLAR B
	ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CODCUC AND A.PKTipoOferta = B.PKTipoOferta 
	WHERE @codpais = 'BO'

	if (@FlagLog = 1)
	print 'update #TMP_DMATRIZCAMPANA1 PrecioOfer = PrecioOfertaDol: ' +
		cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' '
		+ convert(varchar, @m_time, 108) + ' :dd:' + 
		CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR) 
	select @m_time  = GETDATE(), @item = @item+1 

	/*Por cada CUC - TO se le asigna el precio de oferta, exposición total, número de páginas y descuento*/
	UPDATE	#BASE_1
	SET	PrecioOferta = round(B.PrecioOferta,2,1),
		Exposicion = B.Exposicion,
		ExposicionOriginal = B.Exposicion,
		NroPaginas = B.NroPaginas,
		NroPaginasOriginal = B.NroPaginas,
		Descuento = CASE WHEN CONVERT(FLOAT, A.PrecioNormalMN) = 0 THEN 0 ELSE (1 - (CONVERT(FLOAT,round(B.PrecioOferta,2,1))) /(round(CONVERT(FLOAT, A.PrecioNormalMN),2,1))) END,
		FlagDiagramado = 1
	FROM #BASE_1 A INNER JOIN #TMP_DMATRIZCAMPANA1 B 
	ON A.AnioCampana = B.AnioCampana AND A.CODCUC = B.CODCUC AND A.PKTipoOferta = B.PKTipoOferta 
	
	if (@FlagLog = 1) print 'update #BASE_1: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	/*Se aplica 0 a los registros que tengan descuento negativo*/
	UPDATE #BASE_1
	SET Descuento = 0
	WHERE Descuento <0 
	/*Si no fue diagramado no lo considero*/
	/*Si el CUC-TO no fue diagramado lo elimino, es una reacción*/
	DELETE FROM #BASE_1 WHERE FlagDiagramado = 0
	
	if (@FlagLog = 1) print 'update #BASE_1 and delete: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	/*
		Apoyados
		Si lo apoyan menos de 10 productos no se considera el precio 
	*/
	IF OBJECT_ID('tempdb..#Apoyados') is not null
	DROP TABLE #Apoyados

	SELECT AnioCampana, B.CodCUC, D.CodTipoOferta, COUNT(DISTINCT C.CodCUC) AS NroApoyados
	INTO #Apoyados
	FROM DAPOYOPRODUCTO A INNER JOIN DPRODUCTO B ON A.PKProductoApoyador = B.PKProducto
	INNER JOIN DPRODUCTO C ON A.PKProductoApoyado = C.PKProducto
	INNER JOIN DTIPOOFERTA D ON A.PKTipoOfertaApoyador = D.PKTipoOferta
	WHERE AnioCampana BETWEEN @AnioCampanaIni AND @AnioCampanaFinFuturo
	GROUP BY AnioCampana, B.CodCUC, D.CodTipoOferta
	HAVING COUNT(DISTINCT C.CodCUC) < 10 
	
	if (@FlagLog = 1) print 'create #Apoyados: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	--Si el precio del producto en un TO de set y/0 apoyados es el mínimo entonces considero el promedio con los otros TOs
	IF OBJECT_ID('tempdb..#TMP_PrecioSets') is not null
	DROP TABLE #TMP_PrecioSets

	SELECT AnioCampana, CodCUC, A.CodTipoOferta, PrecioOferta 
	INTO #TMP_PrecioSets 
	FROM #BASE_1 A
	INNER JOIN #ListaTO D ON A.CodTipoOferta = D.CodTipoOferta
	WHERE d.FlagSet = 1
	-- CodTipoOferta IN ('008', '035', '036', '060', '049', '012', '038', '039') 
	AND PrecioOferta > 0

		
	if (@FlagLog = 1) print 'create #TMP_PrecioSets: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	IF OBJECT_ID('tempdb..#Apoyados1') is not null
	DROP TABLE #Apoyados1

	SELECT A.AnioCampana, A.CodCUC, A.CodTipoOferta, PrecioOferta 
	INTO #Apoyados1
	FROM #BASE_1 A 
	INNER JOIN #Apoyados B ON A.ANIOCAMPANA = B.ANIOCAMPANA AND A.CODCUC = B.CodCUC
	
	if (@FlagLog = 1) print 'create #Apoyados1: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	IF OBJECT_ID('tempdb..#TMP_PromedioSets ') is not null
	DROP TABLE #TMP_PromedioSets 

	SELECT A.ANIOCAMPANA, A.CODCUC, MIN(A.PrecioOferta) AS PrecioOfertaTotal, round(MIN(B.PrecioOferta),2,1) AS PrecioOfertaSet, 
	CASE WHEN MIN(A.PrecioOferta) = MIN(B.PrecioOferta) THEN 1 ELSE 0 END AS FlagPromedio 
	INTO #TMP_PromedioSets 
	FROM #BASE_1 A 
	INNER JOIN #TMP_PrecioSets B ON A.ANIOCAMPANA = B.ANIOCAMPANA AND A.CODCUC = B.CodCUC
	GROUP BY A.ANIOCAMPANA, A.CODCUC
	UNION 
	SELECT A.ANIOCAMPANA, A.CODCUC, MIN(A.PrecioOferta) AS PrecioOfertaTotal, round(MIN(B.PrecioOferta),2,1) AS PrecioOfertaSet, 
	CASE WHEN MIN(A.PrecioOferta) = MIN(B.PrecioOferta) THEN 1 ELSE 0 END AS FlagPromedio 
	FROM #BASE_1 A 
	INNER JOIN #Apoyados1 B ON A.ANIOCAMPANA = B.ANIOCAMPANA AND A.CODCUC = B.CodCUC
	GROUP BY A.ANIOCAMPANA, A.CODCUC
	
	if (@FlagLog = 1) print 'create #TMP_PromedioSets: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	---------------------select * from #BASE_1
	IF OBJECT_ID('tempdb..#TMP_MIN') is not null
	DROP TABLE #TMP_MIN

	SELECT A.AnioCampana, A.CodCUC, MIN(A.PrecioOferta) AS PrecioOfertaMIN, CONVERT(FLOAT,0) AS PrecioOfertaSet
	INTO #TMP_MIN
	FROM #BASE_1 A INNER JOIN #TMP_PromedioSets B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC 
	WHERE FlagPromedio = 1
	GROUP BY A.AnioCampana, A.CodCUC
	
	if (@FlagLog = 1) print 'create #TMP_MIN: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	IF OBJECT_ID('tempdb..#TMP_Promedio') is not null
	DROP TABLE #TMP_Promedio 

	SELECT A.AnioCampana, A.CodCUC, AVG(PrecioOferta) as PrecioOferta 
	INTO #TMP_Promedio 
	FROM #BASE_1 A 
	INNER JOIN #TMP_PromedioSets B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC 
	WHERE FlagPromedio = 1
	GROUP BY A.AnioCampana, A.CodCUC
	
	if (@FlagLog = 1) print 'create #TMP_Promedio: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #TMP_MIN
	SET PrecioOfertaSet = B.PrecioOferta
	FROM #TMP_MIN A INNER JOIN #TMP_Promedio B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	
	if (@FlagLog = 1) print 'UPDATE #TMP_MIN: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_1
	SET PrecioOferta = B.PrecioOfertaSet,
		Descuento = CASE WHEN CONVERT(FLOAT, A.PrecioNormalMN) = 0 THEN 0 ELSE (1 - (CONVERT(FLOAT, B.PrecioOfertaSet) /CONVERT(FLOAT, A.PrecioNormalMN))) END
	FROM #BASE_1 A 
	INNER JOIN #TMP_MIN B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC AND A.PrecioOferta = B.PrecioOfertaMIN
	
	if (@FlagLog = 1) print 'UPDATE #BASE_1: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	IF OBJECT_ID('tempdb..#SinExposicion') is not null
	DROP TABLE #SinExposicion 

	--Si es que el producto no fue diagramado, entonces le coloco los mínimo para no alterar los promedios
	--DROP TABLE #SinExposicion
	SELECT DISTINCT AnioCampana, CodCUC 
	INTO #SinExposicion 
	FROM #BASE_1 WHERE Exposicion = 0
	
	if (@FlagLog = 1) print 'create #SinExposicion: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	IF OBJECT_ID('tempdb..#ExposicionMinima') is not null
	DROP TABLE #ExposicionMinima

	SELECT A.AnioCampana, A.CodCUC, MIN(Exposicion) AS Exposicion
	INTO #ExposicionMinima
	FROM #BASE_1 A INNER JOIN #SinExposicion B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE Exposicion > 0
	GROUP BY A.AnioCampana, A.CodCUC

	if (@FlagLog = 1) print 'create #ExposicionMinima: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_1
	SET Exposicion = B.Exposicion
	FROM #BASE_1 A INNER JOIN #ExposicionMinima B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE A.Exposicion = 0
	
	if (@FlagLog = 1) print 'UPDATE #BASE_1, Exposicion: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	IF OBJECT_ID('tempdb..#SinPrecioOferta') is not null
	DROP TABLE #SinPrecioOferta 

	SELECT DISTINCT AnioCampana, CodCUC 
	INTO #SinPrecioOferta 
	FROM #BASE_1 WHERE PrecioOferta = 0

	IF OBJECT_ID('tempdb..#PrecioOfertaMinimo') is not null
	DROP TABLE #PrecioOfertaMinimo

	SELECT A.AnioCampana, A.CodCUC, MIN(PrecioOferta) AS PrecioOferta, MIN(Descuento) AS Descuento
	INTO #PrecioOfertaMinimo
	FROM #BASE_1 A INNER JOIN #SinPrecioOferta B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE PrecioOferta > 0
	GROUP BY A.AnioCampana, A.CodCUC

	if (@FlagLog = 1) print 'create #PrecioOfertaMinimo: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_1
	SET PrecioOferta = B.PrecioOferta,
		Descuento = B.Descuento
	FROM #BASE_1 A INNER JOIN #PrecioOfertaMinimo B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE A.PrecioOferta = 0

	if (@FlagLog = 1) print 'create #BASE_1, PrecioOferta, Descuento: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	--CodPais se le agrega replace para quitar los 2 espacios en blanco que tiene
	IF OBJECT_ID('tempdb..#BASE_3') is not null
	DROP TABLE #BASE_3

	SELECT replace(@CodPais,' ','') AS CodPais, 
	A.AnioCampana, 
	A.DesMarca, 
	A.CodCUC,
	A.CodCategoria,
	A.DesCategoria,
	0 AS N_Records_SKU,
	0 AS NCampaign,
	CASE WHEN A.AnioCampana <= '201710' THEN 1 ELSE 0 END AS Development,
	CASE WHEN A.AnioCampana <= @AnioCampanaFin THEN B.RealNroPedidos ELSE 0 END AS RealNroPedidos,
	AVG(PrecioOferta) AS PrecioOfertaProm,
	MIN(PrecioOferta) AS PrecioOfertaMin,
	POWER(MIN(PrecioOferta),2) AS PrecioOfertaMinAlCuadrado,
	CASE WHEN MIN(PrecioOferta) = 0 THEN 0 ELSE 1/MIN(PrecioOferta) END AS PrecioOfertaMinInverso,
	MAX(PrecioOferta) AS PrecioOfertaMax,
	POWER(MAX(PrecioOferta),2) AS PrecioOfertaMaxAlCuadrado,
	CASE WHEN MAX(PrecioOferta) = 0 THEN 0 ELSE 1/MAX(PrecioOferta) END AS PrecioOfertaMaxInverso,
	AVG(PrecioNormalMN) AS PrecioNormalMN, 
	COUNT(DISTINCT PkTipoOferta) AS NroTipoOfertas,
	SUM(FlagCatalogo) AS NroTipoOfertasCatalogo,
	SUM(FlagRevista) AS NroTipoOfertasRevista,
	SUM(RealUUVendidas + RealUUFaltantes) AS RealUUDemandadas, 
	round(CONVERT(FLOAT,SUM(RealUUVendidas + RealUUFaltantes)) /CONVERT(FLOAT,B.RealNroPedidos),10,1) AS PUP, 
	MIN(Exposicion) AS ExposicionMin,
	SQRT(MIN(Exposicion)) AS ExposicionMinRaizCuadrada,
	MAX(Exposicion) AS ExposicionMax, 
	SQRT(MAX(Exposicion)) AS ExposicionMaxRaizCuadrada,
	SUM(ExposicionOriginal) AS ExposicionTotal,
	MAX(Descuento) AS MaxDescuento,
	POWER(MAX(Descuento),2) AS MaxDescuentoCuadrado,
	CASE WHEN MAX(Descuento) > 0.6 THEN 1 ELSE 0 END AS FlagDescuentoMayor60,
	CASE WHEN MAX(Descuento) > 0.7 THEN 1 ELSE 0 END AS FlagDescuentoMayor70,
	CONVERT(FLOAT, 0) AS MaxDescuentoRevista,
	CONVERT(FLOAT, 0) AS MaxDescuentoCatalogo,
	CONVERT(FLOAT, 0) AS FactorDemoCatalogo,
	0 AS FlagMaxDescuentoRevista,
	0 AS UbicacionCaratula, 
	0 AS UbicacionContracaratula, 
	0 AS UbicacionPoster, 
	0 AS UbicacionInserto, 
	0 AS UbicacionPrimeraPagina, 
	0 AS UbicacionOtros, 
	0 AS LadoDerecho, 
	0 AS LadoAmbos, 
	0 AS LadoIzquierdo, 
	NroPaginas = SUM(ISNULL(NroPaginas,0)), 
	0 AS FotoProducto,
	0 AS FotoModelo, 
	0 AS FlagDiscover, 
	0 AS FlagTacticaMacro,
	0 AS FlagTacticaDetallada,
	CASE WHEN @CodPais = 'BO' AND  RIGHT(A.aniocampana,2) = '04' THEN 1
		 WHEN @CodPais = 'DO' AND  RIGHT(A.aniocampana,2) = '11' THEN 1	
		 WHEN @CodPais IN ('CL','CO','CR','EC','SV','GT','MX','PA','PE','PR') AND RIGHT(A.aniocampana,2) = '09' THEN 1
		 ELSE 0 END AS FlagDiaPadre, --modificar
	CASE WHEN @CodPais IN ('BO','DO') AND  RIGHT(A.aniocampana,2) = '08' THEN 1
		 WHEN @CodPais = 'CR' AND  RIGHT(A.aniocampana,2) = '12' THEN 1	
		 WHEN @CodPais IN ('CL','CO','EC','SV','GT','MX','PA','PE','PR') AND RIGHT(A.aniocampana,2) = '07' THEN 1
		ELSE 0 END AS FlagDiaMadre, --modificar
	CASE WHEN RIGHT(A.AnioCampana,2) IN ('17', '18') THEN 1 ELSE 0 END AS FlagNavidad,
	CASE WHEN RIGHT(A.AnioCampana,2) = '01' THEN 1 ELSE 0 END AS FlagC01,
	CASE WHEN RIGHT(A.AnioCampana,2) = '02' THEN 1 ELSE 0 END AS FlagC02,
	0 AS FlagRegalo,
	0 AS TO_003_OfertaConsultora,
	0 AS TO_005_NuevoEnPromocion,
	0 AS TO_007_Apoyados,
	0 AS TO_008_Especiales,
	0 AS TO_009_PromocionPropia,
	0 AS TO_011_OfertasPrincipales,
	0 AS TO_012_OfertasPrincipales,
	0 AS TO_013_Especiales,
	0 AS TO_014_BloquePosterContra,
	0 AS TO_015_Especiales,
	0 AS TO_017_Especiales,
	0 AS TO_018_Especiales,
	0 AS TO_019_RestoLínea,
	0 AS TO_029_OfertaConsultora,
	0 AS TO_033_PromocionPropia,
	0 AS TO_035_FechasEspeciales,
	0 AS TO_036_FechasEspeciales,
	0 AS TO_038_FechasEspeciales,
	0 AS TO_039_FechasEspeciales,
	0 AS TO_043_Especiales,
	0 AS TO_044_PromPuntual,
	0 AS TO_047_PromocionPropia,
	0 AS TO_048_OfertaConsultora,
	0 AS TO_049_OfertaConsultora,
	0 AS TO_060_OfertaConsultora,
	0 AS TO_106_Oferta1x2x3x,
	0 AS TO_114_PromocionPropia,
	0 AS TO_116_PromocionInsuperable,
	0 AS TO_123_OfertaConsultora,
	cast(null as varchar(400)) SubCategory,
	cast(0 as int) CatalogDurationDays,
	cast(0 as float) PrecioOfertaPromInf, 
	cast(0 as float) PrecioOfertaMinInf,
	cast(0 as float) PrecioOfertaMinAlCuadradoInf, 
	cast(0 as float) PrecioOfertaMinInversoInf, 
	cast(0 as float) PrecioOfertaMaxInf, 
	cast(0 as float) PrecioNormalMNInf, 
	cast(0 as float) PrecioOfertaPromUSD, 
	cast(0 as float) PrecioOfertaMinUSD, 
	cast(0 as float) PrecioOfertaMaxUSD, 
	cast(0 as float) PrecioNormalMNUSD 

	INTO #BASE_3
	FROM #BASE_1 A INNER JOIN FNUMPEDCAM B ON A.AnioCampana = B.AnioCampana
	GROUP BY A.AnioCampana, A.DesMarca, A.CodCUC, A.CodCategoria, A.DesCategoria, B.RealNroPedidos

	if (@FlagLog = 1) print 'create #BASE_3: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	DELETE FROM #BASE_3 WHERE PrecioOfertaMin = 0

	if (@FlagLog = 1) print 'delete #BASE_3: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET UbicacionCaratula = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE ISNULL(DesUbicacionCatalogo,'') IN ('CARATULA', 'CARATULA Y CONTRACARATULA')

	if (@FlagLog = 1) print 'UPDATE #BASE_3, UbicacionCaratula: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET UbicacionContracaratula = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE ISNULL(DesUbicacionCatalogo,'') IN ('CONTRA CARATULA', 'CARATULA Y CONTRACARATULA') 

	if (@FlagLog = 1) print 'UPDATE #BASE_3, UbicacionContracaratula: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET UbicacionPoster = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE ISNULL(DesUbicacionCatalogo,'') IN ('POSTER')

	if (@FlagLog = 1) print 'UPDATE #BASE_3, UbicacionPoster: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET UbicacionInserto = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE ISNULL(DesUbicacionCatalogo,'') IN ('INSERTO')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, UbicacionInserto: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET UbicacionPrimeraPagina = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE ISNULL(DesUbicacionCatalogo,'') IN ('PRIMERA PAGINA (2 Y 3)')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, UbicacionPrimeraPagina: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET UbicacionOtros = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE ISNULL(DesUbicacionCatalogo,'') IN ('OTROS / CUALQUIER PAGINA', '')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, UbicacionOtros: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET LadoDerecho = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE DesLadoPag = 'LADO DERECHO'
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, LadoDerecho: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET LadoAmbos = 1 
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE DesLadoPag = 'EN AMBOS LADOS'
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, LadoAmbos: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET LadoIzquierdo = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE DesLadoPag = 'LADO IZQUIERDO'
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, LadoIzquierdo: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET FotoProducto = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.FotoProducto = 'S'
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, FotoProducto: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET FotoModelo = 1 
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.FotoModelo = 'S'
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, FotoModelo: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET FlagDiscover = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE ISNULL(B.FlagDiscover,0) = 1
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, FlagDiscover: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET FlagRegalo = 1
	FROM #BASE_3 A 
	INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('007', '029', '048')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, FlagRegalo: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_003_OfertaConsultora = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('003')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_003_OfertaConsultora: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_005_NuevoEnPromocion = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('005')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_005_NuevoEnPromocion: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_007_Apoyados = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('007')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_007_Apoyados: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_008_Especiales = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('008')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_008_Especiales: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_009_PromocionPropia = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('009')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_009_PromocionPropia: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_011_OfertasPrincipales = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('011')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_011_OfertasPrincipales: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_012_OfertasPrincipales = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('012')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_012_OfertasPrincipales: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_013_Especiales = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('013')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_013_Especiales: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_014_BloquePosterContra = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('014')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_014_BloquePosterContra: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_015_Especiales = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('015')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_015_Especiales: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_017_Especiales = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('017')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_017_Especiales: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_018_Especiales = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('018')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_018_Especiales: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_019_RestoLínea = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('019')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_019_RestoLínea: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_029_OfertaConsultora = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('029')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_029_OfertaConsultora: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_033_PromocionPropia = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('033')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_033_PromocionPropia: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR) 
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_035_FechasEspeciales = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('035')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_035_FechasEspeciales: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_036_FechasEspeciales = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('036')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_036_FechasEspeciales: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_038_FechasEspeciales = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('038')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_038_FechasEspeciales: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1
	
	UPDATE #BASE_3
	SET TO_039_FechasEspeciales = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('039')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_039_FechasEspeciales: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_043_Especiales = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('043')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_043_Especiales: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_044_PromPuntual= 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('044')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_044_PromPuntual: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_047_PromocionPropia= 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('047')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_044_PromocionPropia: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1

	UPDATE #BASE_3
	SET TO_048_OfertaConsultora = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('048')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_048_OfertaConsultora: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_049_OfertaConsultora = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('049')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_049_OfertaConsultora: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_060_OfertaConsultora = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('060')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_060_OfertaConsultora: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_106_Oferta1x2x3x = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('106')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_106_Oferta1x2x3x: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_114_PromocionPropia = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('114')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_114_PromocionPropia: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1

	UPDATE #BASE_3
	SET TO_116_PromocionInsuperable = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('116')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_116_PromocionInsuperable: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET TO_123_OfertaConsultora = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('123')
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, TO_123_OfertaConsultora: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET FlagTacticaMacro = 1
	FROM #BASE_3 A 
	INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	INNER JOIN #ListaTO D ON B.CodTipoOferta = d.CodTipoOferta
	WHERE d.Tactica = 'Macro'
	--B.CodTipoOferta IN ('001', '003', '004', '005', '006', '009', '011', '012', '013', '014', '025',  ---, '010'
	-- '029', '033', '035', '044', '048', '049', '060', '106', '114', '116', '117', '123') ---, '064', '108', '115'


	if (@FlagLog = 1) print 'UPDATE #BASE_3, FlagTacticaMacro: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET FlagTacticaDetallada = 1
	FROM #BASE_3 A INNER JOIN #TMP_DMATRIZCAMPANA B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE B.CodTipoOferta IN ('007', '008','015', '016', '017', '018', '019', '036', '038', '039', '043', '047') 
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, FlagTacticaDetallada: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	-- -- --DROP TABLE #BASE_DESCUENTO
	IF OBJECT_ID('tempdb..#BASE_DESCUENTO') is not null
	DROP TABLE #BASE_DESCUENTO

	SELECT ANIOCAMPANA, CODCUC, FlagCatalogo, FlagRevista, MAX(Descuento) AS DescuentoMaximo 
	INTO #BASE_DESCUENTO 
	FROM #BASE_1
	GROUP BY ANIOCAMPANA, CODCUC, FlagCatalogo, FlagRevista 
	
	if (@FlagLog = 1) print 'create #BASE_DESCUENTO: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET MaxDescuentoRevista = CASE WHEN FlagRevista = 1 THEN DescuentoMaximo ELSE 0 END
	FROM #BASE_3 A INNER JOIN #BASE_DESCUENTO B  ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE FlagRevista = 1
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, MaxDescuentoRevista: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET MaxDescuentoCatalogo = CASE WHEN FlagCatalogo = 1 THEN DescuentoMaximo ELSE 0 END
	FROM #BASE_3 A INNER JOIN #BASE_DESCUENTO B  ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	WHERE FlagCatalogo = 1
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, MaxDescuentoCatalogo: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET FactorDemoCatalogo = MaxDescuentoCatalogo * MaxDescuentoRevista,
	FlagMaxDescuentoRevista = CASE WHEN MaxDescuentoRevista > MaxDescuentoCatalogo THEN 1 ELSE 0 END   
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, FactorDemoCatalogo: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	-- --DROP TABLE #TMP_CAMPANA
	IF OBJECT_ID('tempdb..#TMP_CAMPANA') is not null
	DROP TABLE #TMP_CAMPANA

	SELECT DISTINCT AnioCampana 
	INTO #TMP_CAMPANA 
	FROM #BASE_3
	
	if (@FlagLog = 1) print 'CREATE #TMP_CAMPANA: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	-- --DROP TABLE #TMP_CAMPANA1
	IF OBJECT_ID('tempdb..#TMP_CAMPANA1') is not null
	DROP TABLE #TMP_CAMPANA1

	SELECT AnioCampana, ROW_NUMBER() OVER(ORDER BY AnioCampana ASC) AS Ncampaign 
	INTO #TMP_CAMPANA1 
	FROM #TMP_CAMPANA
	
	if (@FlagLog = 1) print 'CREATE #TMP_CAMPANA1: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET Ncampaign = B.Ncampaign
	FROM #BASE_3 A INNER JOIN #TMP_CAMPANA1 B ON A.AnioCampana = B.AnioCampana
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, Ncampaign: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	-- -- --DROP TABLE #TMP_CAMPANACUC
	IF OBJECT_ID('tempdb..#TMP_CAMPANACUC') is not null
	DROP TABLE #TMP_CAMPANACUC

	SELECT DISTINCT AnioCampana, CodCUC INTO #TMP_CAMPANACUC FROM #BASE_3
	
	if (@FlagLog = 1) print 'CREATE #TMP_CAMPANACUC: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	-- --DROP TABLE #TMP_CAMPANACUC1
	IF OBJECT_ID('tempdb..#TMP_CAMPANACUC1') is not null
	DROP TABLE #TMP_CAMPANACUC1

	SELECT AnioCampana, CodCUC, ROW_NUMBER() OVER(PARTITION BY CodCUC ORDER BY AnioCampana ASC) AS N_Records_SKU 
	INTO #TMP_CAMPANACUC1 FROM #TMP_CAMPANACUC
	
	if (@FlagLog = 1) print 'CREATE #TMP_CAMPANACUC1: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	UPDATE #BASE_3
	SET N_Records_SKU = B.N_Records_SKU
	FROM #BASE_3 A INNER JOIN #TMP_CAMPANACUC1 B ON A.AnioCampana = B.AnioCampana AND A.CodCUC = B.CodCUC
	
	if (@FlagLog = 1) print 'UPDATE #BASE_3, N_Records_SKU: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	/* Cambios realizados 20180206 */

	-- P1. Verificar cantidad de campañas
	
	-- P2. Verificar cantidad de registros xcampañas
	--;with CampanasRegistros as
	--(
	--	select CodPais, AnioCampana, count(*) as NroRegistros
	--	from #BASE_3
	--	group by CodPais, AnioCampana
	--)
	--select * from CampanasRegistros
	--where NroRegistros < ( select avg(NroRegistros)-avg(NroRegistros)*0.05 from CampanasRegistros )
	
	--Paso 01: Agregar valores de inflacion

	IF OBJECT_ID('tempdb..#ForecastInput_FactorInf') is not null
	drop table #ForecastInput_FactorInf

	select * 
	into #ForecastInput_FactorInf
	from bddm01.DATAMARTANALITICO.dbo.ForecastInput_FactorInf

	update a
	set 
		a.PrecioOfertaPromInf = a.[PrecioOfertaProm]*[FactorInf],
		a.PrecioOfertaMinInf = a.[PrecioOfertaMin]*[FactorInf],
		a.PrecioOfertaMaxInf = [PrecioOfertaMax]*[FactorInf],
		a.PrecioNormalMNInf	= [PrecioNormalMN]*[FactorInf]
 	from #BASE_3 a
	inner join #ForecastInput_FactorInf b on a.CodPais = b.CodPais and a.AnioCampana = b.AnioCampana

	if (@FlagLog = 1) print 'UPDATE valores de inflacion, 1: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	update #BASE_3 
	set 
		PrecioOfertaMinAlCuadradoInf = [PrecioOfertaMinInf]*[PrecioOfertaMinInf],
		PrecioOfertaMinInversoInf = 1/[PrecioOfertaMinInf]
	
	if (@FlagLog = 1) print 'UPDATE valores de inflacion, 2: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	-- Paso 02: Agregar valores de tasa de cambio
	update a
	set 
		PrecioOfertaPromUSD = [PrecioOfertaProm]/(case when @CodPais = 'BO' then 1.000 Else [RealTCPromedio] End),
		PrecioOfertaMinUSD = [PrecioOfertaMin]/(case when @CodPais = 'BO' then 1.000 Else [RealTCPromedio] End),
		PrecioOfertaMaxUSD = [PrecioOfertaMax]/(case when @CodPais = 'BO' then 1.000 Else [RealTCPromedio] End),
		PrecioNormalMNUSD = [PrecioNormalMN]/(case when @CodPais = 'BO' then 1.000 Else [RealTCPromedio] End)
	from #BASE_3 a
	inner join FNUMPEDCAM b on a.aniocampana = b.aniocampana
	where a.AnioCampana <= @AnioCampanaFin

	if (@FlagLog = 1) print 'UPDATE tasa de cambio: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	-- Paso 03: Agregar valores de cuc-subcategoria
	update a
	set a.SubCategory = b.DesTipo
	from #BASE_3 a
	inner join BDDM01.DATAMARTANALITICO.dbo.ForecastInput_Subcategory b on a.CodCUC = b.CodCuc

	if (@FlagLog = 1) print 'UPDATE cuc-subcategoriao: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	-- Paso 04: Agregar Dias-facturacion
	update a
	set a.CatalogDurationDays = b.CatalogDurationDays
	from #BASE_3 a
	inner join BDDM01.DATAMARTANALITICO.dbo.ForecastInput_CatalogDays b on a.CodPais = b.CodPais and a.AnioCampana = b.AnioCampana

	if (@FlagLog = 1) print 'UPDATE Dias-facturacion: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	-- Paso 05: factorizar Descategoria en acronimos del algoritmo
	update #BASE_3
	set DesCategoria = 
				case DesCategoria 
					when 'CUIDADO PERSONAL' then 'CP'
					when 'FRAGANCIAS' then 'FR'
					when 'MAQUILLAJE' then 'MQ'
					when 'TRATAMIENTO CORPORAL' then 'TC'
					when 'TRATAMIENTO FACIAL' then 'TF'
					when 'ACCESORIOS COSMETICOS' then 'AC'
				END

	if (@FlagLog = 1) print 'UPDATE Descategoria: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	-- Paso 06: Agregar NCampaign
	update a
	set a.NCampaign = b.NCampaign
	from #BASE_3 a
	inner join BDDM01.DATAMARTANALITICO.dbo.ForecastInput_NCampaign b on a.AnioCampana = b.AnioCampana

	if (@FlagLog = 1) print 'UPDATE NCampaign: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	-- Paso 07: 
	-- Paso 08: Elimina campaña futuras ó abiertas
	delete from #BASE_3 where AnioCampana > @AnioCampanaFin

	if (@FlagLog = 1) print 'Elimina campaña futuras ó abiertas: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	-- Paso 09: Campañas cerradas todo los development = 1
	update #BASE_3 
	set Development = 1

	if (@FlagLog = 1) print 'udpate development = 1: ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 

	-- Paso 10: PUP/ UnidadDemandada / NroPedidos :  !=  0 , null, '', NaN
	delete from #BASE_3 
	where isnull(PUP,0) = 0

	if (@FlagLog = 1) print 'PUP/ UnidadDemandada / NroPedidos : ' + cast(@item as varchar) + ' - ' + convert(varchar, @m_time, 103) + ' ' + convert(varchar, @m_time, 108) + ' :dd:' + CAST(datediff(SS, @m_time, GETDATE()) AS VARCHAR)  
	select @m_time  = GETDATE(), @item = @item+1 


	if @CodPais IN ('GT', 'SV')
	begin
		update #BASE_3
		set CodPais = CASE CodPais WHEN 'GT' then 'G2' WHEN 'SV' THEN 'S2' ELSE @CodPais end 

		set @CodPais = CASE @CodPais WHEN 'GT' then 'G2' WHEN 'SV' THEN 'S2' ELSE @CodPais end 
	end
	--select * from #BASE_3 where AnioCampana = 201507
	
	IF @codpais = 'MX'
		delete from #BASE_3
		where [AnioCampana] between 201501 and 201618
	ELSE 
		delete from #BASE_3
		where[AnioCampana] between 201501 and 201518
	
	update #BASE_3
	SET NCampaign = CASE WHEN @CodPais = 'MX' then (left([AnioCampana],4)*1-2017)*18 + right([AnioCampana],2)*1 
	else (left([AnioCampana],4)*1-2016)*18 + right([AnioCampana],2)*1 END

	IF object_id('tempdb..#recorte') is not null 
	DROP TABLE #recorte

	SELECT  *,ROW_NUMBER() OVER (PARTITION BY [CodPais],CodCUC ORDER BY [AnioCampana] asc) AS N_Records_SKU_2
	INTO #recorte
	from #BASE_3

	UPDATE a
	SET N_Records_SKU = b.N_Records_SKU_2
	from #BASE_3 a 
	left join #recorte b on a.CodPais=b.CodPais and a.CodCUC=b.CodCUC and a.AnioCampana=b.AnioCampana

	IF @CodPais IN ('BO','EC','PE')
		Begin
		Delete from BDDM01.DATAMARTANALITICO.DBO.ForecastModel_input_Nuevos_QA 
		WHERE Codpais = @CodPais
		
		INSERT INTO BDDM01.DATAMARTANALITICO.DBO.ForecastModel_input_Nuevos_QA
		SELECT * 
		FROM #BASE_3 order by 2
		end
	ELSE
		Begin
		Delete from DATAMARTANALITICO.DBO.ForecastModel_input_Nuevos_QA 
		WHERE Codpais = @CodPais

		insert into DATAMARTANALITICO.DBO.ForecastModel_input_Nuevos_QA 
		SELECT * FROM #BASE_3 order by 2
		End