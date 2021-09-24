/***
* Name: Tutorial02
* Author: Lili
* Description: Cargar csv
***/

model Tutorial02


global
{
	/* ************************* Parameters ************************** */
	float 	percentage_allowed	<- 0.25		category:'Environment';
	
	
	/* ************************* Files ************************** */
	file streets_shapefile 				<- file("../includes/big_road.shp");
	file residential_blocks_shapefile 	<- file("../includes/BloquesResidencial_3.shp");
	file comercial_blocks_shapefile 	<- file("../includes/BloquesComercial_3.shp");
	
	matrix store_locations 				<- matrix(csv_file("../includes/store_data.csv", true));  // csv con las coordenadas de puntos de interes
	
	
	/* ************************* Maps ************************** */
	geometry shape 		<- envelope(streets_shapefile);
	graph net_street;
	
	
	list<store_point> stores;
	
	init
	{
		create street 				from: streets_shapefile;
		create residential_block 	from: residential_blocks_shapefile;
		create comercial_block 		from: comercial_blocks_shapefile;
		net_street 		<- as_edge_graph(street); 
		
		
		
		create store_point number: store_locations.rows;
		stores <- list(store_point);
		loop i from: 0 to: length(stores) - 1 step:1 {
				point pt 				 <- {float(store_locations[0,i]),float(store_locations[1,i]),0};
				stores[i].entry 		 <- (pt to_GAMA_CRS "EPSG:4326").location;
				stores[i].location 		 <- stores[i].entry;
				stores[i].store 		 <- string(store_locations[5,i]);
				stores[i].capacity 		 <- int(store_locations[6,i]);
				stores[i].people_allowed <- int(stores[i].capacity*percentage_allowed);
		}
		
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


species store_point {
	point 	entry;
	string 	store;
	int 	capacity;
	int		people_allowed	 <- 1;
	int 	current_people	 <- 0;
	float	crowd_percentage <- 0.0;

	
	aspect default 
	{
		draw circle(10) at: location color:rgb(crowd_percentage*255, (1-crowd_percentage)*255, 0); 
	}
}



experiment mi_experimento type:gui{

	
	output{
		display GUI type:opengl 
		{
			species street 				aspect: basico		refresh: false;
			species residential_block 	aspect: basico		refresh: false;
			species comercial_block 	aspect: basico		refresh: false;
			species store_point			aspect: default		;
			
		}
		
	}
}

