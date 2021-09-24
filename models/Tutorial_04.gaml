/***
* Name: Tutorial04
* Author: Lili
* Description: Agregar comportamientos
***/

model Tutorial04


global
{
	/* ************************* Parameters ************************** */
	float 	percentage_allowed	<- 0.25		category:'Environment';
	int		people				<- 10		category:'Scenario';
	
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
		step <-10#s;
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
		
		
		create person number: people;
		create recommendation_system number:1;
		
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
	
	reflex count_people 
	{
		list<person> 	 person_count 	<- person overlapping self;
		current_people <- length(person_count);
		
		
		if people_allowed=0
		{
			people_allowed <-1;
		}
		
		crowd_percentage <- current_people/people_allowed;
	}
}

/* ***************************************************************************************************** */
species person skills:[moving]{
	point 		home;
	int			need_supplies_time;
	int			shopping_time;
	point		goal_place; 
	bool 		go_home;
	
	bool		go_shopping;
	bool		shopping;
	
	float 		speed 				<- 5 #km/#h;
	float		trust				<- 0.5;


	init
	{
		home 				<- any_location_in(one_of(residential_block)); // Para que aparezca en una calle
		location 			<- home;
		need_supplies_time	<- rnd(80);
		go_home 			<- false;
		shopping_time 		<- 0;

		create app number: 1;
	}
	
	
	
	aspect default 
	{
		draw circle(3#m) color: #purple;
	}
	
	
	reflex wait when:(need_supplies_time>0 and !go_home)
	{
		need_supplies_time <- need_supplies_time-1;
	}
	
	
	reflex go_shopping when:(need_supplies_time=0 and !go_shopping and !go_home)
	{
		if(flip(trust))
		{
			goal_place <- check_app(); 
		}
		else
		{
			goal_place <- (store_point closest_to(location, 1))[0].location; 
		}
		
		go_shopping <- true;
		shopping_time <- int(gauss(288.0,60.0)); // Considering that every step equals 10 seconds using minutes it'll be (48,10) ;
	}
	
	
	reflex move
	{
		do goto target: goal_place on:net_street speed: speed  recompute_path: false;
	}
	
	
	reflex stay_in_store when:(location=goal_place  and shopping_time>=0 and go_shopping and !go_home)
	{
		if shopping_time >0
		{
			shopping_time <- shopping_time-1;
		}
		else
		{
			if (flip(0.8))  // go_home
			{
				goal_place <- home;
				go_home <- true;
			}
			else
			{
				go_shopping <- false;
			}
		}
		
	}
	

	
	point check_app
	{
		point selected_place;
		ask app
		{
			selected_place <- request(myself.location)[rnd(0,2)].location;
		}
		return selected_place;
	}
	
	
	
	species app skills:[network]
	{
		
		list<store_point>  request(point coordinates)
		{
			list<store_point> 	recommended_places <- [];
			ask recommendation_system
			{
				recommended_places <- get_recommendations(myself.location);
			}
			return recommended_places;
		}
	}
	
}





species recommendation_system
{
	action get_recommendations(point coordinates)
	{
		list<store_point> recommendations <- (store_point sort_by(each.crowd_percentage)) closest_to(coordinates, 3) ;
		return recommendations;
	}
	
}







experiment mi_experimento type:gui{

	
	output{
		display GUI type:opengl 
		{
			species street 				aspect: basico		refresh: false;
			species residential_block 	aspect: basico		refresh: false;
			species comercial_block 	aspect: basico		refresh: false;
			species store_point			aspect: default	;
			species person				aspect: default ;
			
		}
		
	}
}


