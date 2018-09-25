/*Creacion de tablas temporales para los parametros*/
DROP TABLE IF EXISTS temp_AnioCampanaIni;
DROP TABLE IF EXISTS temp_AnioCampanaFin;
DROP TABLE IF EXISTS temp_AnioCampanaIniFuturo;
DROP TABLE IF EXISTS temp_AnioCampanaFinFuturo;
DROP TABLE IF EXISTS temp_codpais;
DROP TABLE IF EXISTS temp_flagtest;
DROP TABLE IF EXISTS temp_descategoria;
DROP TABLE IF EXISTS temp_descategoria_all;

Create TEMPORARY table temp_AnioCampanaIni (A char(6));
Create TEMPORARY table temp_AnioCampanaFin (A char(6));
Create TEMPORARY table temp_AnioCampanaIniFuturo (A char(6));
Create TEMPORARY table temp_AnioCampanaFinFuturo (A char(6));
Create TEMPORARY table temp_codpais (A char(4));
Create TEMPORARY table temp_flagtest (A INT);
Create TEMPORARY table temp_descategoria (descategoria VARCHAR(100));
Create TEMPORARY table temp_descategoria_all (A VARCHAR(500));

/*Insercion de los parametros en las tablas del dominio a las tablas temporales*/

INSERT into temp_AnioCampanaIni values((select stringvalue from dom_forecast.forecast_parameters where descparameter = 'ANIOCAMPANAINI'));
INSERT into temp_AnioCampanaFin values((select stringvalue from dom_forecast.forecast_parameters where descparameter = 'ANIOCAMPANAFIN'));
INSERT into temp_AnioCampanaIniFuturo values((select stringvalue from dom_forecast.forecast_parameters where descparameter = 'ANIOCAMPANAINIFUTURO'));
INSERT into temp_AnioCampanaFinFuturo values((select stringvalue from dom_forecast.forecast_parameters where descparameter = 'ANIOCAMPANAFINFUTURO'));
INSERT into temp_descategoria_all values((select stringvalue from dom_forecast.forecast_parameters where descparameter = 'CAT_ALL'));
INSERT into temp_descategoria values((select split_part((select a from temp_descategoria_all),',',1)));
INSERT into temp_descategoria values((select split_part((select a from temp_descategoria_all),',',2)));
INSERT into temp_descategoria values((select split_part((select a from temp_descategoria_all),',',3)));
INSERT into temp_descategoria values((select split_part((select a from temp_descategoria_all),',',4)));
INSERT into temp_descategoria values((select split_part((select a from temp_descategoria_all),',',5)));
INSERT into temp_descategoria values((select split_part((select a from temp_descategoria_all),',',6)));


/*Inicio del Proceso con la insercion de todos los paises*/
INSERT into temp_codpais values('BO');
INSERT into temp_codpais values('CL');
INSERT into temp_codpais values('CO');
INSERT into temp_codpais values('CR');
INSERT into temp_codpais values('DO');
INSERT into temp_codpais values('EC');
INSERT into temp_codpais values('GT');
INSERT into temp_codpais values('MX');
INSERT into temp_codpais values('PA');
INSERT into temp_codpais values('PE');
INSERT into temp_codpais values('PR');
INSERT into temp_codpais values('SV');

/*Tipos de Oferta Validos*/
DROP TABLE IF EXISTS temp_ListaTO;

SELECT *
INTO TEMPORARY TABLE temp_ListaTO
FROM dom_forecast.forecast_tipooferta;

/*Precio Normal
		Considerar solo los productos CUC que tienen estimados*/
DROP TABLE IF EXISTS temp_estimados;

SELECT fnc_analitico.dwh_fvtaprocammes.codpais,fnc_analitico.dwh_fvtaprocammes.aniocampana,b.codcuc,
b.codproductogenericoi,c.codtipooferta,
		sum(estuuvendidas) as NroEstimados,
		max(case when fnc_analitico.dwh_fvtaprocammes.codpais = 'BO'then isnull(precionormaldol,0) else isnull(precionormalmn,0)END) as precionormalmn
into TEMPORARY table temp_estimados
from fnc_analitico.dwh_fvtaprocammes
inner join fnc_analitico.dwh_dproducto b on fnc_analitico.dwh_fvtaprocammes.codpais = b.codpais
and fnc_analitico.dwh_fvtaprocammes.pkproducto = b.pkproducto
inner join fnc_analitico.dwh_dtipooferta c on fnc_analitico.dwh_fvtaprocammes.codpais = c.codpais
AND fnc_analitico.dwh_fvtaprocammes.pktipooferta = c.pktipooferta
where aniocampana = aniocampanaref
and aniocampana BETWEEN (select * from temp_AnioCampanaIni) and (select * from temp_AnioCampanafin)
and descategoria in (select * from temp_descategoria)
GROUP BY fnc_analitico.dwh_fvtaprocammes.codpais,fnc_analitico.dwh_fvtaprocammes.aniocampana,b.codcuc,
b.CodProductoGenericoI,c.codtipooferta;
	
/*
		Informacion base del input
		Campanas cerradas: Solo productos que han facturado en la forma de venta catalogo, productos cosmeticos y algunos tipos de oferta
	*/
		DROP TABLE IF EXISTS temp_base;

		SELECT fnc_analitico.dwh_fvtaproebecam.codpais,fnc_analitico.dwh_fvtaproebecam.aniocampana,fnc_analitico.dwh_dproducto.codcuc,fnc_analitico.dwh_fvtaproebecam.pkproducto,
		fnc_analitico.dwh_dproducto.desmarca,fnc_analitico.dwh_dproducto.codcategoria,fnc_analitico.dwh_dproducto.descategoria,fnc_analitico.dwh_dtipooferta.codtipooferta,
		fnc_analitico.dwh_fvtaproebecam.pktipooferta,
		CASE WHEN modo = 'Catálogo' THEN 1 ELSE 0 END AS FlagCatalogo,
		CASE WHEN modo = 'Revista' THEN 1 ELSE 0 END AS FlagRevista, 
		SUM(RealUUVendidas) AS RealUUVendidas, 
		SUM(RealUUFaltantes) AS RealUUFaltantes, 
		1 AS FlagReal, 
		CAST(0 as FLOAT) AS PrecioNormalMN
		INTO TEMPORARY table temp_base
		FROM fnc_analitico.dwh_fvtaproebecam 
		INNER JOIN fnc_analitico.dwh_dproducto ON fnc_analitico.dwh_fvtaproebecam.pkproducto =fnc_analitico.dwh_dproducto.pkproducto 
		AND fnc_analitico.dwh_fvtaproebecam.codpais = fnc_analitico.dwh_dproducto.codpais
		INNER JOIN fnc_analitico.dwh_dtipooferta ON fnc_analitico.dwh_fvtaproebecam.pktipooferta = fnc_analitico.dwh_dtipooferta.pktipooferta
		and fnc_analitico.dwh_fvtaproebecam.codpais = fnc_analitico.dwh_dtipooferta.codpais
		INNER JOIN temp_ListaTO d ON fnc_analitico.dwh_dtipooferta.codtipooferta = d.codigotipooferta
		where aniocampana BETWEEN (select * from temp_AnioCampanaIni) and (select * from temp_AnioCampanafin)
		AND aniocampana = aniocampanaref
		AND fnc_analitico.dwh_dtipooferta.codtipoprofit = '01' --Forma de Venta Catalogo
		AND fnc_analitico.dwh_dproducto.desunidadnegocio IN ('COSMETICOS')
		AND dataset = 1
		and descategoria in (select * from temp_descategoria)
		GROUP BY fnc_analitico.dwh_fvtaproebecam.codpais,fnc_analitico.dwh_fvtaproebecam.aniocampana, codcuc, fnc_analitico.dwh_fvtaproebecam.pkproducto,
		fnc_analitico.dwh_dproducto.desmarca, fnc_analitico.dwh_dproducto.codcategoria,
		fnc_analitico.dwh_dproducto.descategoria, fnc_analitico.dwh_dtipooferta.codtipooferta,
		modo, fnc_analitico.dwh_fvtaproebecam.pktipooferta;
	
	
	/*
		Campanas abiertas: todas las tacticas que han sido ingresadas en Planit y el sistema comercial
	*/ 
	insert into temp_base 
	Select fnc_analitico.dwh_dmatrizcampana2.codpais,fnc_analitico.dwh_dmatrizcampana2.aniocampana,fnc_analitico.dwh_dproducto.codcuc,fnc_analitico.dwh_dmatrizcampana2.pkproducto,
	   fnc_analitico.dwh_dproducto.desmarca,fnc_analitico.dwh_dproducto.codcategoria,fnc_analitico.dwh_dproducto.descategoria,fnc_analitico.dwh_dtipooferta.codtipooferta,
	   fnc_analitico.dwh_dmatrizcampana2.pktipooferta,
	   CASE WHEN modo = 'Catálogo' THEN 1 ELSE 0 END AS FlagCatalogo,
	   CASE WHEN modo = 'Revista' THEN 1 ELSE 0 END AS FlagRevista, 
	   0 AS RealUUVendidas, 
	   0 AS RealUUFaltantes, 
	   0 AS FlagReal, 
	   CAST(0 as FLOAT) AS PrecioNormalMN
	   
	   from fnc_analitico.dwh_dmatrizcampana2
	   INNER JOIN fnc_analitico.dwh_dproducto on fnc_analitico.dwh_dmatrizcampana2.codpais = fnc_analitico.dwh_dproducto.codpais 
	   and fnc_analitico.dwh_dmatrizcampana2.pkproducto = fnc_analitico.dwh_dproducto.pkproducto
	   INNER JOIN fnc_analitico.dwh_dtipooferta on fnc_analitico.dwh_dmatrizcampana2.codpais = fnc_analitico.dwh_dtipooferta.codpais
	   and fnc_analitico.dwh_dmatrizcampana2.pktipooferta = fnc_analitico.dwh_dtipooferta.pktipooferta
	   INNER JOIN temp_ListaTO on fnc_analitico.dwh_dtipooferta.codtipooferta = codigotipooferta
	   where aniocampana BETWEEN (select * from temp_AnioCampanaIniFuturo) and (select * from temp_AnioCampanaFinFuturo)
	   and codtipoprofit = '01'
	   and dataset  = 1
	   and descategoria in (select * from temp_descategoria);

/*Eliminar NroEstimados igual a 0  /revisar/ */
	
	DROP TABLE IF EXISTS temp_prodestimados;
	  
	SELECT b.codpais,b.aniocampana,pkproducto,b.codcuc,b.codproductogenericoi,b.codtipooferta,b.nroestimados
	INTO TEMPORARY TABLE temp_prodestimados
	FROM fnc_analitico.dwh_dproducto 
	INNER JOIN temp_estimados B ON fnc_analitico.dwh_dproducto.codpais = B.codpais AND fnc_analitico.dwh_dproducto.codproductogenericoi = B.codproductogenericoi
	WHERE B.nroestimados = 0;
	  
	DELETE 
	FROM temp_base
	 	USING temp_prodestimados B
	WHERE 	temp_base.codpais = B.codpais AND temp_base.pkproducto = B.pkproducto
	AND temp_base.aniocampana = b.aniocampana AND temp_base.codcuc = b.codcuc AND temp_base.codtipooferta = b.codtipooferta;
	
	
/*Precio Oferta Dolares
	Considerar solo los productos CUC que tienen estimados*/
	DROP TABLE IF EXISTS temp_dolar;
	 
	 SELECT fnc_analitico.dwh_fvtaprocammes.codpais,aniocampana,codcuc, pktipooferta,MAX(isnull(precioofertadol,0)) as precioofertadol
	 INTO TEMPORARY table temp_dolar
	 FROM fnc_analitico.dwh_fvtaprocammes
	 INNER JOIN fnc_analitico.dwh_dproducto on fnc_analitico.dwh_fvtaprocammes.codpais = fnc_analitico.dwh_dproducto.codpais
	 AND fnc_analitico.dwh_fvtaprocammes.pkproducto = fnc_analitico.dwh_dproducto.pkproducto
	 WHERE aniocampana = aniocampanaref
	 AND aniocampana BETWEEN (select * from temp_AnioCampanaIni) and (select * from temp_AnioCampanaFinFuturo)
	 AND descategoria in (select * from temp_descategoria)
	 GROUP BY fnc_analitico.dwh_fvtaprocammes.codpais,aniocampana, codcuc, pktipooferta;

	/*Se actualiza el precio normal de cada CUC*/
	
	UPDATE temp_base
	set precionormalmn = B.precionormalmn
	from temp_estimados B
	where 
	temp_base.codpais = b.codpais
	and temp_base.aniocampana = B.aniocampana
	and temp_base.codcuc = B.codcuc
	and temp_base.codtipooferta = B.codtipooferta
	and b.nroestimados > 0;

	/*De la matriz de facturacion se traen las variables de argumentacion y el precio Oferta 
	Se debe tomar en cuenta lo siguiente para campanas cerradas:
	Forma de Venta: Catalogo
	La tactica debe tener registrada la ubicacion.
	La tactica debe estar diagramada solo en la revista o en los catÃ¡logos
	El codigo de Venta debe ser diferente a 00000, este es un cÃ³digo dummy de tacticas que llegan a Sicc desde Planit, pero que no se llegan a activar
	El precio de oferta del producto debe ser mayor a 0
	
	*/
	DROP TABLE IF EXISTS temp_destipocatalogo_all;
	
	SELECT stringvalue
	into TEMPORARY table temp_destipocatalogo_all
	from dom_forecast.forecast_parameters where descparameter = 'TIPOCATALOGO_ALL';
	
	DROP TABLE IF EXISTS temp_destipocatalogo;
		
	Create TEMPORARY table temp_destipocatalogo (destipocatalogo VARCHAR(50));
	
	INSERT into temp_destipocatalogo values((select split_part((select * from temp_destipocatalogo_all),',',1)));
	INSERT into temp_destipocatalogo values((select split_part((select * from temp_destipocatalogo_all),',',2)));
	INSERT into temp_destipocatalogo values((select split_part((select * from temp_destipocatalogo_all),',',3)));
	INSERT into temp_destipocatalogo values((select split_part((select * from temp_destipocatalogo_all),',',4)));
	INSERT into temp_destipocatalogo values((select split_part((select * from temp_destipocatalogo_all),',',5)));
	INSERT into temp_destipocatalogo values((select split_part((select * from temp_destipocatalogo_all),',',6)));
	INSERT into temp_destipocatalogo values((select split_part((select * from temp_destipocatalogo_all),',',7)));
	
	DROP TABLE IF EXISTS temp_dmatrizcampana_prodgenerico;
	
	SELECT A.codpais,aniocampana,c.codcuc,c.codproductogenericoi,
	A.pktipooferta,b.codtipooferta,desubicacioncatalogo,
	desladopag, destipocatalogo, CASE WHEN desexposicion is null THEN COALESCE(desexposicion::INT,0)
	ELSE  
	COALESCE(
			 CAST(
			 	RIGHT(
			 		RTRIM(
			 			REPLACE(
			 				REPLACE(COALESCE(desexposicion,''),'SIN EXPOSICION','')
			 			,'%','')
			 		)			 		 
			 	,4)
			 AS FLOAT) 
		,0)
		/ 100 * nropaginas END AS exposicion,
		nropaginas,
		MAX(COALESCE(fotoproducto,'')) AS fotoproducto,
		MAX(COALESCE(fotomodelo,'')) AS fotomodelo,
		MAX(COALESCE(flagdiscover,'')) AS flagdiscover,
		paginacatalogo,
		CAST(0 AS FLOAT) AS preciooferta,
		1 AS registros,
		1 AS eliminar
	
	INTO TEMPORARY TABLE temp_dmatrizcampana_prodgenerico
	FROM fnc_analitico.dwh_dmatrizcampana2 A
	INNER JOIN fnc_analitico.dwh_dtipooferta B on A.codpais = B.codpais and A.pktipooferta = B.pktipooferta
	INNER JOIN fnc_analitico.dwh_dproducto C on A.codpais = C.codpais and A.pkproducto = C.pkproducto
	WHERE aniocampana BETWEEN (select * from temp_AnioCampanaIni) and (select * from temp_AnioCampanaFin)
	AND b.codtipoprofit = '01'
	AND desubicacioncatalogo IS NOT NULL
	AND codventa <> '00000'
	AND destipocatalogo IN (SELECT destipocatalogo FROM temp_destipocatalogo)
	GROUP BY A.codpais, aniocampana,c.codcuc,c.codproductogenericoi,A.pktipooferta,b.codtipooferta,desubicacioncatalogo,
	desladopag, destipocatalogo, desexposicion, nropaginas, paginacatalogo
	UNION
	/*Campañas abiertas:
	Forma de Venta: Catálogo
	La táctica debe estar diagramada solo en la revista o en los catalogos
	*/
	SELECT fnc_analitico.dwh_dmatrizcampana2.codpais,aniocampana,c.codcuc,c.codproductogenericoi,
	fnc_analitico.dwh_dmatrizcampana2.pktipooferta,b.codtipooferta,desubicacioncatalogo,
	desladopag, destipocatalogo, CASE WHEN desexposicion is null then COALESCE(desexposicion::INT,0)
	ELSE
	COALESCE(
			 CAST(
			 	RIGHT(
			 		RTRIM(
			 			REPLACE(
			 				REPLACE(COALESCE(desexposicion,''),'SIN EXPOSICION','')
			 			,'%','')
			 		)			 		 
			 	,4)
			 AS FLOAT) 
		,0) / 100 * nropaginas END AS exposicion,
		nropaginas,
		MAX(COALESCE(fotoproducto,'')) AS fotoproducto,
		MAX(COALESCE(fotomodelo,'')) AS fotomodelo,
		MAX(COALESCE(flagdiscover,'')) AS flagdiscover,
		paginacatalogo,
		CAST(0 AS FLOAT) AS preciooferta,
		1 AS registros,
		1 AS eliminar
	
	FROM fnc_analitico.dwh_dmatrizcampana2
	INNER JOIN fnc_analitico.dwh_dtipooferta B ON fnc_analitico.dwh_dmatrizcampana2.codpais = b.codpais AND fnc_analitico.dwh_dmatrizcampana2.pktipooferta = b.pktipooferta
	INNER JOIN fnc_analitico.dwh_dproducto C ON fnc_analitico.dwh_dmatrizcampana2.codpais = c.codpais AND fnc_analitico.dwh_dmatrizcampana2.pkproducto = c.pkproducto
	WHERE aniocampana BETWEEN (select * from temp_AnioCampanaIniFuturo) and (select * from temp_AnioCampanaFinFuturo)
	AND b.codtipoprofit = '01'
	AND destipocatalogo IN (SELECT destipocatalogo FROM temp_destipocatalogo)
	GROUP BY fnc_analitico.dwh_dmatrizcampana2.codpais,aniocampana,c.codcuc,c.codproductogenericoi,
	fnc_analitico.dwh_dmatrizcampana2.pktipooferta,b.codtipooferta,desubicacioncatalogo,desladopag,
	destipocatalogo,desexposicion,nropaginas,paginacatalogo;
	
	/*Se ingresa la información a una nueva temporal para calcular los campos*/
	DROP TABLE IF EXISTS temp_dmatrizcampana;
	
	SELECT codpais,aniocampana,codcuc,pktipooferta,codtipooferta,desubicacioncatalogo,desladopag,destipocatalogo,
	SUM(COALESCE(exposicion,0)) AS exposicion,
	nropaginas,
	MAX(fotoproducto) AS fotoproducto,
	MAX(fotomodelo) AS fotomodelo,
	MAX(flagdiscover) AS flagdiscover,
	paginacatalogo,
	ROUND(MIN(preciooferta),2) AS preciooferta,
	MAX(registros) AS registros,
	MAX(eliminar) AS eliminar
	INTO TEMPORARY TABLE temp_dmatrizcampana
	FROM temp_dmatrizcampana_prodgenerico
	GROUP BY codpais,aniocampana,codcuc,pktipooferta,codtipooferta,desubicacioncatalogo,desladopag,destipocatalogo,
	nropaginas,paginacatalogo;
	
	/*Se actualiza el precio de Oferta*/
	DROP TABLE IF EXISTS temp_preciooferta;
	
	SELECT 
	fnc_analitico.dwh_dmatrizcampana2.codpais,aniocampana,c.descategoria,c.codcuc,fnc_analitico.dwh_dmatrizcampana2.pktipooferta,b.codtipooferta, MIN(preciooferta) AS preciooferta
	INTO TEMPORARY TABLE temp_preciooferta
	FROM fnc_analitico.dwh_dmatrizcampana2
	INNER JOIN fnc_analitico.dwh_dtipooferta B ON fnc_analitico.dwh_dmatrizcampana2.codpais = b.codpais
	AND fnc_analitico.dwh_dmatrizcampana2.pktipooferta = b.pktipooferta
	INNER JOIN fnc_analitico.dwh_dproducto C ON fnc_analitico.dwh_dmatrizcampana2.codpais = c.codpais
	AND fnc_analitico.dwh_dmatrizcampana2.pkproducto = c.pkproducto
	WHERE aniocampana BETWEEN (select * from temp_AnioCampanaIni) and (select * from temp_AnioCampanaFin)
	AND b.codtipoprofit = '01'
	AND codventa <> '00000'
	AND destipocatalogo IN (SELECT destipocatalogo FROM temp_destipocatalogo)
	AND preciooferta > 0 
	GROUP BY fnc_analitico.dwh_dmatrizcampana2.codpais,aniocampana,c.descategoria,c.codcuc,fnc_analitico.dwh_dmatrizcampana2.pktipooferta,b.codtipooferta;
	
	UPDATE temp_dmatrizcampana
	SET preciooferta = b.preciooferta
	FROM temp_preciooferta B
	WHERE temp_dmatrizcampana.codpais = b.codpais
	AND temp_dmatrizcampana.aniocampana = b.aniocampana
	AND temp_dmatrizcampana.codcuc = b.codcuc
	AND temp_dmatrizcampana.codtipooferta = b.codtipooferta;
	
	DELETE temp_dmatrizcampana WHERE preciooferta = 0;
	
	/*Se eliminan las tacticas de la revista que estan ubicadas en la pagina 0 o ubicadas en una pagina mayor a 100, porque normalmente son reacciones*/
	
	DELETE FROM temp_dmatrizcampana
	WHERE destipocatalogo IN ('REVISTA BELCORP')
	AND (COALESCE(paginacatalogo,0) = 0
	OR COALESCE(paginacatalogo,0) >= 100);
	
	/*Agrupamos por producto - tipo de oferta*/
	DROP TABLE IF EXISTS temp_dmatrizcampana1;
	
	SELECT codpais,aniocampana,codcuc,pktipooferta,MIN(preciooferta) AS preciooferta,
	SUM(COALESCE(exposicion,0)) AS exposicion, SUM(COALESCE(nropaginas,0)) AS nropaginas
	INTO TEMPORARY TABLE temp_dmatrizcampana1
	FROM temp_dmatrizcampana
	GROUP BY codpais,aniocampana,codcuc,pktipooferta;
	
	/*Agrupamos por CUC - Tipo de Oferta para totalizar las unidades vendidas y las unidades faltantes*/
	DROP TABLE IF EXISTS temp_base1;
	
	SELECT codpais, aniocampana,codcuc,desmarca,codcategoria,descategoria,codtipooferta,pktipooferta,flagcatalogo,
	flagrevista,SUM(realuuvendidas) AS realuuvendidas, SUM(realuufaltantes) AS realuufaltantes, flagreal, CAST(0 AS FLOAT) AS preciooferta,
	CAST(0 AS FLOAT) AS exposicion, AVG(precionormalmn) AS precionormalmn, 0 AS nropaginas,CAST(0 AS FLOAT) AS descuento,
	0 AS nropaginasoriginal, CAST(0 AS FLOAT) AS exposicionoriginal, 0 AS flagdiagramado
	INTO TEMPORARY TABLE temp_base1
	FROM temp_base
	GROUP BY codpais, aniocampana,codcuc,desmarca,codcategoria,descategoria,codtipooferta,pktipooferta,flagcatalogo,
	flagrevista,flagreal;
	
	UPDATE temp_dmatrizcampana1
	SET preciooferta = 0
	WHERE codpais = 'BO';
	
	UPDATE temp_dmatrizcampana1
	SET preciooferta  = TRUNC(B.precioofertadol,2)
	FROM temp_dolar B
	WHERE temp_dmatrizcampana1.codpais = B.codpais
	AND temp_dmatrizcampana1.aniocampana = B.aniocampana
	AND temp_dmatrizcampana1.codcuc = B.codcuc
	AND temp_dmatrizcampana1.pktipooferta = B.pktipooferta
	AND temp_dmatrizcampana1.codpais = 'BO';
	
	/*Por cada CUC - TO se le asigna el precio de oferta, exposicion total, nÃºmero de paginas y descuento*/
	
	UPDATE temp_base1
	SET preciooferta = TRUNC(b.preciooferta,2),
		exposicion = b.exposicion,
		exposicionoriginal = b.exposicion,
		nropaginas = b.nropaginas,
		nropaginasoriginal = b.nropaginas,
		descuento = CASE WHEN CAST(temp_base1.precionormalmn AS FLOAT) = 0 THEN 0 ELSE (1-((CAST(TRUNC(b.preciooferta,2) AS FLOAT))/(TRUNC(CAST(temp_base1.precionormalmn AS FLOAT),2)))) END,
		flagdiagramado = 1
	FROM temp_dmatrizcampana1 B
	WHERE temp_base1.codpais = b.codpais
	AND temp_base1.aniocampana = b.aniocampana
	AND temp_base1.codcuc = b.codcuc
	AND temp_base1.pktipooferta = b.pktipooferta;
	
	/*Se aplica 0 a los registros que tengan descuento negativo*/
	
	UPDATE temp_base1
	SET descuento = 0
	WHERE descuento < 0;
	
	/*Si no fue diagramado no lo considero*/
	/*Si el CUC-TO no fue diagramado lo elimino, es una reaccion*/
	
	DELETE FROM temp_base1 WHERE flagdiagramado = 0;
	
	/*
		Apoyados
		Si lo apoyan menos de 10 productos no se considera el precio 
	*/
	DROP TABLE IF EXISTS temp_apoyados;
	
	SELECT fnc_analitico.dwh_dapoyadoproducto.codpais,aniocampana,b.codcuc,d.codtipooferta,COUNT(DISTINCT c.codcuc) AS nroapoyados
	INTO TEMPORARY TABLE temp_apoyados
	FROM fnc_analitico.dwh_dapoyadoproducto
	INNER JOIN fnc_analitico.dwh_dproducto B ON fnc_analitico.dwh_dapoyadoproducto.codpais = b.codpais
	AND pkproductoapoyador = b.pkproducto 
	INNER JOIN fnc_analitico.dwh_dproducto C ON fnc_analitico.dwh_dapoyadoproducto.codpais = c.codpais
	AND pkproductoapoyado = c.pkproducto
	INNER JOIN fnc_analitico.dwh_dtipooferta D ON fnc_analitico.dwh_dapoyadoproducto.codpais = d.codpais
	AND pktipoofertaapoyador = d.pktipooferta
	WHERE fnc_analitico.dwh_dapoyadoproducto.aniocampana BETWEEN (select * from temp_AnioCampanaIni) and (select * from temp_AnioCampanaFinFuturo)
	GROUP BY fnc_analitico.dwh_dapoyadoproducto.codpais,aniocampana,b.codcuc,d.codtipooferta
	HAVING COUNT(DISTINCT c.codcuc) <10;
	
	/*Si el precio del producto en un TO de set y/0 apoyados es el minimo entonces considero el promedio con los otros TOs*/
	DROP TABLE IF EXISTS temp_preciosets;
	
	SELECT 	codpais,aniocampana,codcuc,codtipooferta,preciooferta
	INTO TEMPORARY TABLE temp_preciosets
	FROM temp_base1
	INNER JOIN temp_listaTO B ON codtipooferta = B.codigotipooferta
	WHERE b.flagset = 1
	AND preciooferta >0; 
	
	/*merge entre apoyados y base1*/
	DROP TABLE IF EXISTS temp_apoyados1;
	
	SELECT temp_base1.codpais, temp_base1.aniocampana, temp_base1.codcuc, temp_base1.codtipooferta,preciooferta
	INTO TEMPORARY TABLE temp_apoyados1
	FROM temp_base1
	INNER JOIN temp_apoyados B ON temp_base1.codpais = b.codpais AND  temp_base1.aniocampana = b.aniocampana 
	AND  temp_base1.codcuc = b.codcuc;
	
	/*Crear temporal de promediosets, los precios se minimos de los sets*/
	DROP TABLE IF EXISTS temp_promediosets;
	
	SELECT temp_base1.codpais,temp_base1.aniocampana,temp_base1.codcuc,MIN(temp_base1.preciooferta) AS precioofertatotal,
	TRUNC(MIN(b.preciooferta),2) AS precioofertaset,
	CASE WHEN MIN(temp_base1.preciooferta) = MIN(b.preciooferta) THEN 1 ELSE 0 END AS flagpromedio
	INTO TEMPORARY TABLE temp_promediosets
	FROM temp_base1
	INNER JOIN temp_preciosets B ON temp_base1.codpais = b.codpais AND temp_base1.aniocampana = b.aniocampana
	AND temp_base1.codcuc = b.codcuc
	GROUP BY temp_base1.codpais,temp_base1.aniocampana,temp_base1.codcuc
	
	UNION
	SELECT temp_base1.codpais,temp_base1.aniocampana,temp_base1.codcuc,MIN(temp_base1.preciooferta) AS precioofertatotal,
	TRUNC(MIN(b.preciooferta),2) AS precioofertaset,
	CASE WHEN MIN(temp_base1.preciooferta) = MIN(b.preciooferta) THEN 1 ELSE 0 END AS flagpromedio
	FROM temp_base1
	INNER JOIN temp_apoyados1 B ON temp_base1.codpais = b.codpais AND temp_base1.aniocampana = b.aniocampana
	AND temp_base1.codcuc = b.codcuc
	GROUP BY temp_base1.codpais,temp_base1.aniocampana,temp_base1.codcuc;

	/*Crear temporal de precios minimos*/
	DROP TABLE IF EXISTS temp_min;
	
	SELECT temp_base1.codpais,temp_base1.aniocampana,temp_base1.codcuc,MIN(temp_base1.preciooferta) AS precioofertamin,
	CAST(0 AS FLOAT) AS precioofertaset
	INTO TEMPORARY TABLE temp_min
	FROM temp_base1 INNER JOIN temp_promediosets B ON temp_base1.codpais = b.codpais 
	AND temp_base1.aniocampana = b.aniocampana 
	AND temp_base1.codcuc = b.codcuc
	WHERE flagpromedio = 1
	GROUP BY temp_base1.codpais,temp_base1.aniocampana,temp_base1.codcuc;
	
	/*Crear temporal de precios de oferta promedios*/
	DROP TABLE IF EXISTS temp_promedio;
	
	SELECT temp_base1.codpais,temp_base1.aniocampana,temp_base1.codcuc,AVG(preciooferta) AS preciooferta
	INTO TEMPORARY TABLE temp_promedio
	FROM temp_base1 INNER JOIN temp_promediosets B ON temp_base1.codpais = b.codpais 
	AND temp_base1.aniocampana = b.aniocampana 
	AND temp_base1.codcuc = b.codcuc
	WHERE flagpromedio = 1
	GROUP BY temp_base1.codpais,temp_base1.aniocampana,temp_base1.codcuc;
	
	/*Actualizar temporales*/
	
	UPDATE temp_min
	SET precioofertaset = b.preciooferta
	FROM temp_promedio b
	WHERE temp_min.codpais = b.codpais AND temp_min.aniocampana = b.aniocampana
	AND temp_min.codcuc = b.codcuc;
	
	UPDATE temp_base1
	SET preciooferta = b.precioofertaset,
		descuento = CASE WHEN CAST(temp_base1.precionormalmn AS FLOAT) = 0 THEN 0 ELSE (1 - (CAST(b.precioofertaset AS FLOAT))/CAST(temp_base1.precionormalmn AS FLOAT)) END
	FROM temp_min B
	WHERE temp_base1.codpais = b.codpais AND temp_base1.aniocampana = b.aniocampana 
	AND temp_base1.codcuc = b.codcuc AND temp_base1.preciooferta = b.precioofertamin;
	
	/*Si es que el producto no fue diagramado, entonces le coloco los minimo para no alterar los promedios*/
	DROP TABLE IF EXISTS temp_sinexposicion;
	
	SELECT DISTINCT codpais,aniocampana, codcuc 
	INTO TEMPORARY TABLE temp_sinexposicion 
	FROM temp_base1 WHERE exposicion = 0;
	
	/*Crear temp de expo minima*/
	DROP TABLE IF EXISTS temp_exposicionminima;
	
	SELECT temp_base1.codpais,temp_base1.aniocampana,temp_base1.codcuc,MIN(exposicion) AS exposicion
	INTO TEMPORARY TABLE temp_exposicionminima
	FROM temp_base1 INNER JOIN temp_sinexposicion B ON temp_base1.codpais = b.codpais 
	AND temp_base1.aniocampana = b.aniocampana AND temp_base1.codcuc = b.codcuc
	WHERE exposicion > 0
	GROUP BY temp_base1.codpais,temp_base1.aniocampana,temp_base1.codcuc;
	
	/*Actualizar Base1*/
	
	UPDATE temp_base1
	SET exposicion = b.exposicion
	FROM temp_exposicionminima B 
	WHERE temp_base1.codpais = b.codpais 
	AND temp_base1.aniocampana = b.aniocampana
	AND temp_base1.codcuc = b.codcuc
	AND temp_base1.exposicion = 0;
	
	/*Crear tabla sin precio oferta en 0*/
	DROP TABLE IF EXISTS temp_sinpreciooferta;
	
	SELECT DISTINCT codpais, aniocampana,codcuc
	INTO TEMPORARY TABLE temp_sinpreciooferta
	FROM temp_base1 where preciooferta = 0;
	
	/*Crear tabla precio oferta minimo y descuento minimo*/
	DROP TABLE IF EXISTS temp_precioofertaminimo;
	
	SELECT temp_base1.codpais,temp_base1.aniocampana,temp_base1.codcuc,MIN(preciooferta) AS preciooferta, MIN(descuento) AS descuento
	INTO TEMPORARY TABLE temp_precioofertaminimo
	FROM temp_base1 
	INNER JOIN temp_sinpreciooferta B ON temp_base1.codpais = b.codpais AND temp_base1.aniocampana = b.aniocampana 
	AND temp_base1.codcuc = b.codcuc
	WHERE preciooferta > 0
	GROUP BY temp_base1.codpais, temp_base1.aniocampana,temp_base1.codcuc;
	
	UPDATE temp_base1
	SET preciooferta = b.preciooferta
	FROM temp_precioofertaminimo B WHERE temp_base1.codpais = b.codpais AND temp_base1.aniocampana = b.aniocampana
	AND temp_base1.codcuc = b.codcuc
	AND temp_base1.preciooferta = 0;
	
	/*CodPais se le agrega replace para quitar los 2 espacios en blanco que tiene
	 aqui no es necesario este cambio efectuado en sql
	*/
	DROP TABLE IF EXISTS temp_base2;
	
	SELECT 
	temp_base1.codpais AS CodPais,temp_base1.aniocampana AS AnioCampana,temp_base1.desmarca AS DesMarca,
	temp_base1.codcuc AS CodCUC, temp_base1.codcategoria AS CodCategoria, temp_base1.descategoria AS DesCategoria,
	0 AS N_Records_SKU,
	0 AS NCampaign,
	CASE WHEN temp_base1.aniocampana <= '201710' THEN 1 ELSE 0 END AS Development,
	CASE WHEN temp_base1.aniocampana <= 201802 /*(SELECT * FROM temp_aniocampanafin)*/ THEN b.realnropedidos ELSE 0 END AS RealNroPedidos,
	AVG(preciooferta) AS PrecioOfertaProm,
	MIN(preciooferta) AS PrecioOfertaMin,
	POWER(MIN(preciooferta),2) AS PrecioOfertaMinAlCuadrado,
	CASE WHEN MIN(preciooferta) = 0 THEN 0 ELSE 1/MIN(preciooferta) END AS PrecioOfertaMinInverso,
	MAX(preciooferta) AS PrecioOfertaMax,
	POWER(MAX(preciooferta),2) AS PrecioOfertaMaxAlCuadrado,
	CASE WHEN MIN(preciooferta) = 0 THEN 0 ELSE 1/MIN(preciooferta) END AS PrecioOfertaMaxInverso,
	AVG(precionormalmn) AS PrecioNormalMN,
	COUNT(DISTINCT pktipooferta) AS NroTipoOfertas,
	SUM(flagcatalogo) AS NroTipoOfertasCatalogo,
	SUM(flagrevista) AS NroTipoOfertasRevista,
	SUM(realuuvendidas + realuufaltantes) AS RealUUDemandadas,
	TRUNC(CAST(SUM(realuuvendidas + realuufaltantes) AS FLOAT)/ CAST(b.realnropedidos AS FLOAT),10) AS PUP,
	MIN(exposicion) AS ExposicionMin,
	SQRT(MAX(exposicion)) AS ExposicionMinRaizCuadrada,
	MAX(exposicion) AS ExposicionMax,
	SQRT(MAX(exposicion)) AS ExposicionMaxRaizCuadrada,
	SUM(exposicionoriginal) AS ExposicionTotal,
	MAX(descuento) AS MaxDescuento,
	POWER(MAX(descuento),2) MaxDescuentoCuadrado,
	CASE WHEN MAX(descuento) > 0.6 THEN 1 ELSE 0 END AS FlagDescuentoMayor60,
	CASE WHEN MAX(descuento) > 0.7 THEN 1 ELSE 0 END AS FlagDescuentoMayor70,
	CAST(0 AS FLOAT) AS MaxDescuentoRevista,
	CAST(0 AS FLOAT) AS MaxDescuentoCatalogo,
	CAST(0 AS FLOAT) AS FactorDemoCatalogo,
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
	SUM(COALESCE(nropaginas,0)) as nropaginas,
	0 AS FotoProducto,
	0 AS FotoModelo, 
	0 AS FlagDiscover, 
	0 AS FlagTacticaMacro,
	0 AS FlagTacticaDetallada,
	CASE WHEN temp_base1.codpais = 'BO' AND  RIGHT(temp_base1.aniocampana,2) = '04' THEN 1
		 WHEN temp_base1.codpais = 'DO' AND  RIGHT(temp_base1.aniocampana,2) = '11' THEN 1	
		 WHEN temp_base1.codpais IN ('CL','CO','CR','EC','SV','GT','MX','PA','PE','PR') AND RIGHT(temp_base1.aniocampana,2) = '09' THEN 1
		 ELSE 0 END AS FlagDiaPadre, --modificar
	CASE WHEN temp_base1.codpais IN ('BO','DO') AND  RIGHT(temp_base1.aniocampana,2) = '08' THEN 1
		 WHEN temp_base1.codpais = 'CR' AND  RIGHT(temp_base1.aniocampana,2) = '12' THEN 1	
		 WHEN temp_base1.codpais IN ('CL','CO','EC','SV','GT','MX','PA','PE','PR') AND RIGHT(temp_base1.aniocampana,2) = '07' THEN 1
		ELSE 0 END AS FlagDiaMadre, --modificar
	CASE WHEN RIGHT(temp_base1.aniocampana,2) IN ('17', '18') THEN 1 ELSE 0 END AS FlagNavidad,
	CASE WHEN RIGHT(temp_base1.aniocampana,2) = '01' THEN 1 ELSE 0 END AS FlagC01,
	CASE WHEN RIGHT(temp_base1.aniocampana,2) = '02' THEN 1 ELSE 0 END AS FlagC02,
	0 AS FlagRegalo,
	0 AS TO_003_OfertaConsultora,
	0 AS TO_007_Apoyados,
	0 AS TO_008_Especiales,
	0 AS TO_011_OfertasPrincipales,
	0 AS TO_013_Especiales,
	0 AS TO_014_BloquePosterContra,
	0 AS TO_015_Especiales,
	0 AS TO_017_Especiales,
	0 AS TO_018_Especiales,
	0 AS TO_019_RestoLinea,
	0 AS TO_029_OfertaConsultora,
	0 AS TO_033_PromocionPropia,
	0 AS TO_035_FechasEspeciales,
	0 AS TO_036_FechasEspeciales,
	0 AS TO_043_Especiales,
	0 AS TO_044_PromPuntual,
	0 AS TO_048_OfertaConsultora,
	0 AS TO_049_OfertaConsultora,
	0 AS TO_060_OfertaConsultora,
	0 AS TO_106_Oferta1x2x3x,
	0 AS TO_116_PromocionInsuperable,
	0 AS TO_117_Nuevo1x2x,
	0 AS TO_123_OfertaConsultora,
	cast(null AS varchar(400)) SubCategory,
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
	
	INTO TEMPORARY TABLE temp_base2
	FROM temp_base1  INNER JOIN fnc_analitico.dwh_fnumpedcam2 B ON temp_base1.codpais = B.codpais
	AND temp_base1.aniocampana = b.aniocampana 
	GROUP BY temp_base1.CodPais, temp_base1.AnioCampana, temp_base1.DesMarca,temp_base1.CodCUC, temp_base1.CodCategoria,
	temp_base1.DesCategoria,B.RealNroPedidos;
	
	DELETE FROM temp_base2 WHERE PrecioOfertaMin = 0;
	
	UPDATE temp_base2
	SET UbicacionCaratula = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND COALESCE(DesubicacionCatalogo,'') IN ('CARATULA','CARATULA Y CONTRACARATULA');
	
	UPDATE temp_base2
	SET UbicacionContracaratula = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND COALESCE(DesubicacionCatalogo,'') IN ('CONTRA CARATULA','CARATULA Y CONTRACARATULA');
	
	UPDATE temp_base2
	SET UbicacionPoster = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND COALESCE(DesubicacionCatalogo,'') IN ('POSTER');
	
	UPDATE temp_base2
	SET UbicacionInserto = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND COALESCE(DesubicacionCatalogo,'') IN ('INSERTO');
	
	UPDATE temp_base2
	SET UbicacionPrimeraPagina = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND COALESCE(DesUbicacionCatalogo,'') IN ('PRIMERA PAGINA (2 Y 3)');
	
	UPDATE temp_base2
	SET UbicacionOtros = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND COALESCE(DesubicacionCatalogo,'') IN ('OTROS / CUALQUIER PAGINA', '');
	
	UPDATE temp_base2
	SET LadoDerecho = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND DesLadoPag = 'LADO DERECHO';
	
	UPDATE temp_base2
	SET LadoAmbos = 1 
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND DesLadoPag = 'EN AMBOS LADOS';
	
	UPDATE temp_base2
	SET LadoIzquierdo = 1 
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND DesLadoPag = 'LADO IZQUIERDO';
	
	UPDATE temp_base2
	SET FotoProducto = 1 
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.FotoProducto = 'S';
	
	UPDATE temp_base2
	SET FotoModelo = 1 
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.FotoModelo = 'S';
	
	UPDATE temp_base2
	SET FlagDiscover = 1 
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND COALESCE(B.FlagDiscover,'') = 1;/*Revisar si es '' o 0*/

	UPDATE temp_base2
	SET FlagRegalo = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('007', '029', '048');
	
	UPDATE temp_base2
	SET TO_003_OfertaConsultora = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('003');
	
	UPDATE temp_base2
	SET TO_007_Apoyados = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('007');
	
	UPDATE temp_base2
	SET TO_008_Especiales = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('008');
	
	UPDATE temp_base2
	SET TO_011_OfertasPrincipales = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('011');
	
	UPDATE temp_base2
	SET TO_013_Especiales = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('013');
	
	UPDATE temp_base2
	SET TO_014_BloquePosterContra = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('014');
	
	UPDATE temp_base2
	SET TO_015_Especiales = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('015');
	
	UPDATE temp_base2
	SET TO_017_Especiales = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('017');
	
	UPDATE temp_base2
	SET TO_018_Especiales = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('018');
	
	UPDATE temp_base2
	SET TO_019_RestoLinea = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('019');
	
	UPDATE temp_base2
	SET TO_029_OfertaConsultora = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('029');
	
	UPDATE temp_base2
	SET TO_033_PromocionPropia = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('033');
	
	UPDATE temp_base2
	SET TO_035_FechasEspeciales = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('035');
	
	UPDATE temp_base2
	SET TO_036_FechasEspeciales = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('036');
	
	UPDATE temp_base2
	SET TO_043_Especiales = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('043');
	
	UPDATE temp_base2
	SET TO_044_PromPuntual= 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('044');
	
	UPDATE temp_base2
	SET TO_048_OfertaConsultora = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('048');
	
	UPDATE temp_base2
	SET TO_049_OfertaConsultora = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('049');
	
	UPDATE temp_base2
	SET TO_060_OfertaConsultora = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('060');
	
	UPDATE temp_base2
	SET TO_106_Oferta1x2x3x = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('106');
	
	UPDATE temp_base2
	SET TO_116_PromocionInsuperable = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('116');
	
	UPDATE temp_base2
	SET TO_117_Nuevo1x2x= 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('117');
	
	UPDATE temp_base2
	SET TO_123_OfertaConsultora = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN ('123');
	
	UPDATE temp_base2
	SET FlagTacticaMacro = 1
	FROM (select * FROM temp_dmatrizcampana INNER JOIN temp_listaTO ON codtipooferta = codigotipooferta WHERE tactica = 'Macro') B 
	WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc;
	
	UPDATE temp_base2
	SET FlagTacticaDetallada = 1
	FROM temp_dmatrizcampana B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND B.CodTipoOferta IN (SELECT CodigoTipoOferta FROM temp_listaTO WHERE tactica = 'Detallada' AND dataset = 1); --revisar
	
	/*Tabla temporal del descuento maximo que se tiene por cuc*/
	DROP TABLE IF EXISTS temp_basedescuento;
	
	SELECT CodPais,AnioCampana,CodCUC,FlagCatalogo, FlagRevista, MAX(Descuento) AS DescuentoMaximo 
	INTO TEMPORARY TABLE temp_basedescuento 
	FROM temp_base1
	GROUP BY CodPais,AnioCampana,CodCUC,FlagCatalogo, FlagRevista;
	
	UPDATE temp_base2
	SET MaxDescuentoRevista = CASE WHEN FlagRevista = 1 THEN DescuentoMaximo ELSE 0 END
	FROM temp_basedescuento B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND FlagRevista = 1;
	
	UPDATE temp_base2
	SET MaxDescuentoCatalogo = CASE WHEN FlagCatalogo = 1 THEN DescuentoMaximo ELSE 0 END
	FROM temp_basedescuento B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc
	AND FlagCatalogo = 1;
	
	UPDATE temp_base2
	SET FactorDemoCatalogo = MaxDescuentoCatalogo * MaxDescuentoRevista,
	FlagMaxDescuentoRevista = CASE WHEN MaxDescuentoRevista > MaxDescuentoCatalogo THEN 1 ELSE 0 END
	WHERE aniocampana >= 201501;   
	
	/*Se buscan los aniocampana que se encuentran en la tabla base2*/
	DROP TABLE IF EXISTS temp_campana;
	
	SELECT DISTINCT AnioCampana 
	INTO TEMPORARY TABLE temp_campana 
	FROM temp_base2;
	
	/*Se crea una tabla que cuenta el numero de veces que se repite un anicampana y los enumera de foram creciente*/	
	DROP TABLE IF EXISTS temp_campana1;
	
	SELECT AnioCampana, ROW_NUMBER() OVER(ORDER BY AnioCampana ASC) AS Ncampaign 
	INTO TEMPORARY TABLE temp_campana1
	FROM temp_campana;
	
	UPDATE temp_base2
	SET Ncampaign = B.Ncampaign
	FROM temp_campana1 B WHERE temp_base2.AnioCampana = B.AnioCampana;
	
	/*Crear tabla que almacene CUC por Pais y anio*/
	DROP TABLE IF EXISTS temp_campanacuc;
	
	SELECT DISTINCT codpais,AnioCampana, CodCUC 
	INTO TEMPORARY TABLE temp_campanacuc
	FROM temp_base2;
	
	/*Se enumeran las veces que un cuc ha aparecido en la historia*/
	DROP TABLE IF EXISTS temp_campanacuc1;
	
	SELECT codpais, AnioCampana, CodCUC, ROW_NUMBER() OVER(PARTITION BY codpais,CodCUC ORDER BY AnioCampana ASC) AS N_Records_SKU 
	INTO TEMPORARY TABLE temp_campanacuc1 
	FROM temp_campanacuc;
	
	UPDATE temp_base2
	SET N_Records_SKU = B.N_Records_SKU
	FROM temp_campanacuc1 B WHERE temp_base2.codpais = B.codpais AND temp_base2.aniocampana = B.aniocampana
	AND temp_base2.codcuc = b.codcuc;
	
	/* Cambios realizados 20180206 */

		
	--Paso 01: Agregar valores de inflacion
	DROP TABLE IF EXISTS temp_factorinf;
	
	SELECT * 
	INTO TEMPORARY TABLE temp_factorinf
	FROM dom_forecast.forecast_factor_inf;
	
	UPDATE temp_base2
	SET precioofertaprominf = precioofertaprom*b.factorinf,
		precioofertamininf = precioofertamin*b.factorinf,
		precioofertamaxinf = precioofertamax*b.factorinf,
		precionormalmninf = precionormalmn*b.factorinf
	FROM temp_factorinf B WHERE temp_base2.codpais = b.codpais AND temp_base2.aniocampana = b.aniocampana;
		
	UPDATE temp_base2
	set PrecioOfertaMinAlCuadradoInf = [PrecioOfertaMinInf]*[PrecioOfertaMinInf],
		PrecioOfertaMinInversoInf = 1/[PrecioOfertaMinInf]
	WHERE aniocampana >= 201501;
	
	/*Paso 02: Agregar valores de tasa de cambio*/
	
	UPDATE temp_base2
	SET 
		PrecioOfertaPromUSD = PrecioOfertaProm/(case when temp_base2.codpais = 'BO' then 1.000 Else RealTCPromedio End),
		PrecioOfertaMinUSD = PrecioOfertaMin/(case when temp_base2.CodPais = 'BO' then 1.000 Else RealTCPromedio End),
		PrecioOfertaMaxUSD = PrecioOfertaMax/(case when temp_base2.CodPais = 'BO' then 1.000 Else RealTCPromedio End),
		PrecioNormalMNUSD = PrecioNormalMN/(case when temp_base2.CodPais = 'BO' then 1.000 Else RealTCPromedio End)
	FROM fnc_analitico.dwh_fnumpedcam2 B
	WHERE  temp_base2.codpais = b.codpais AND temp_base2.aniocampana = b.aniocampana
	AND temp_base2.AnioCampana <= (SELECT * FROM temp_aniocampanafin);
	
	/*Paso 03: Agregar valores de cuc-subcategoria*/
	
	UPDATE temp_base2
	SET SubCategory = b.DesTipo
	FROM  dom_forecast.forecast_subcategory b WHERE temp_base2.CodCUC = b.CodCuc;
	
	/*Paso 04: Agregar Dias-facturacion*/
	
	UPDATE temp_base2
	SET CatalogDurationDays = b.CatalogoDurationDays
	FROM dom_forecast.forecast_catalog_days b WHERE temp_base2.CodPais = b.CodPais AND temp_base2.AnioCampana = b.AnioCampana;
	
	/* Paso 05: factorizar Descategoria en acronimos del algoritmo*/
	
	UPDATE  temp_base2
	SET DesCategoria = 
				CASE DesCategoria 
					when 'CUIDADO PERSONAL' then 'CP'
					when 'FRAGANCIAS' then 'FR'
					when 'MAQUILLAJE' then 'MQ'
					when 'TRATAMIENTO CORPORAL' then 'TC'
					when 'TRATAMIENTO FACIAL' then 'TF'
					when 'ACCESORIOS COSMETICOS' then 'AC'
				END
	WHERE Aniocampana >= 201501;

	/* Paso 06: Agregar NCampaign*/
				
	UPDATE temp_base2
	set NCampaign = b.NCampaing
	FROM dom_forecast.forecast_ncampaign b WHERE temp_base2.AnioCampana = b.AnioCampana;
	
	/*  Paso 07: Elimina campana futuras o abiertas*/
	
	DELETE FROM temp_base2 WHERE AnioCampana > (SELECT * FROM temp_aniocampanafin);
	
	/*  Paso 08: CampaÃ±as cerradas todo los development = 1*/
	
	UPDATE temp_base2
	SET Development = 1
	WHERE aniocampana>= 201501;
	
	/*  Paso 09: PUP/ UnidadDemandada / NroPedidos :  !=  0 , null, '', NaN*/
	
	DELETE FROM temp_base2
	WHERE COALESCE(PUP,0) = 0;
	
	/*        **********************************   */
	/*  Parte de almacenaje de la información en un repositorio */
	/*        **********************************   */
		
	/*Se construye un temporal donde se almacena la informacion final */
	DROP TABLE IF EXISTS temp_base3;
	
	SELECT *
	INTO TEMPORARY TABLE temp_base3
	FROM temp_base2
	ORDER by codpais,aniocampana,desmarca,descategoria;

	/*Se elimina el contenido del repositorio para insertar la nueva data generada*/	
	DELETE FROM dom_forecast.forecast_input_qas WHERE codpais IS NOT NULL;
	
	INSERT INTO dom_forecast.forecast_input_qas  
	select * FROM temp_base3;
	
	/*Aquí están los comandos para visualizar la data y contar el numero de resgistros*/
	--DELETE from dom_forecast.forecast_input_qas  where codpais = 'PR' and aniocampana = '201810'
	--select DISTINCT aniocampana,count(aniocampana) from dom_forecast.forecast_input_qas where codpais = 'PR' group by aniocampana order by 1;
	--select DISTINCT count(aniocampana),count from dom_forecast.forecast_input_qas where codpais = 'PR' group by aniocampana order by 1;
	--select DISTINCT aniocampana,count(aniocampana) from fnc_analitico.dwh_fvtaproebecam where codpais = 'PR'group by aniocampana order by 1 