/***
* Name: Tutorial_01
* Author: Lili
* Description: Creando el agente global y el ambiente
***/

model Tutorial_01


global
{
	
	file streets_shapefile 				<- file("../includes/big_road.shp");
	file residential_blocks_shapefile 	<- file("../includes/BloquesResidencial_3.shp");
	file comercial_blocks_shapefile 	<- file("../includes/BloquesComercial_3.shp");
	
	geometry shape 		<- envelope(streets_shapefile);
	graph net_street;
	
	
	
	init
	{
		create street 				from: streets_shapefile;
		create residential_block 	from: residential_blocks_shapefile;
		create comercial_block 		from: comercial_blocks_shapefile;
		net_street 		<- as_edge_graph(street); 
	}
	
}


// Environment species
species street{
	aspect basico{
		draw shape color:#black;
	}
}

species residential_block{
	aspect basico{
		draw shape color:rgb(26,82,119,100);
	}
}

species comercial_block{
	int 	current_people;
	aspect basico{
		draw shape color:rgb(70,26,50,100);
	}
}





experiment mi_experimento type:gui{

	
	output{
		display GUI type:opengl 
		{
			species street 				aspect: basico		refresh: false;
			species residential_block 	aspect: basico		refresh: false;
			species comercial_block 	aspect: basico		refresh: false;
			
		}
		
	}
}
