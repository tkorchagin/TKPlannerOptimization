infinity(10000000000).
fakepart(fakepart).

const_direction(10000).
const_fact(100).
const_add(1000).

min_rest(16).

/*
source(id(t1),exceed(1)). 
source(id(t2),exceed(1)). 
source(id(t3),exceed(1)).
source(id(t4),exceed(1)).

sink(id(r1),need(1)).
sink(id(r2),need(1)).

allowed_sources(sink(r1),sources([t1,t3,t4])). 
allowed_sources(sink(r2),sources([t3,t4])).

crosscost(source(t1),sink(r1),cost(650)).
crosscost(source(t1),sink(r2),cost(2)).
crosscost(source(t2),sink(r1),cost(1)).
crosscost(source(t2),sink(r2),cost(10)).
crosscost(source(t3),sink(r1),cost(50)).
crosscost(source(t3),sink(r2),cost(30)).
crosscost(source(t4),sink(r1),cost(502)).
crosscost(source(t4),sink(r2),cost(1)).

*/


+!start
<-
	.my_name(MyName);
	+start_time(system.time);
	.print("main started");
	
	!process_data;
	//!add_fake_source;
	.print("finished processing");
	
	.create_agent(tp,"src/transportation.asl");
	.findall(source(id(ID),exceed(CAP)), source(id(ID),exceed(CAP)), Sources);
	.findall(sink(id(Id),need(Cap)), sink(id(Id),need(Cap)),Sinks);
	.findall(crosscost(source(Id1),sink(Id2),cost(Cost)),
		crosscost(source(Id1),sink(Id2),cost(Cost)),	
			Costs);
	.length(Sources,Nsources);
	.length(Sinks,Nsinks);
	.length(Costs,Ncosts);
	.send(tp,tell,[nsources(Nsources),
		nsinks(Nsinks),
		ncosts(Ncosts),
		parent(MyName)]);
	
	.send(tp,tell,Sources);
	.print(send(tp,tell,Sources));
	
	.send(tp,tell,Sinks);
	.print(send(tp,tell,Sinks));
	
	.send(tp,tell,Costs);
	.print(send(tp,tell,Costs));
	
	.send(tp,tell,epsilon_factor(100));
	.print(send(tp,tell,epsilon_factor(100)));
	
	.send(tp,achieve,start);
	.print(send(tp,achieve,start));
.	


+!process_data <- 
	/*
		+part_direction_norm(
			direction(2001939893),
			depot(2000036956),
			part_norms(
				[
					[1,2],[2,2],[3,2],[4,2],[5,0],[6,1],[7,2],[8,0]
				]
			)
		)
	
		+team(id(2002108559), depot(2000036518), Mode, State)
		+team_allowed(team(2002093013),direction(2001939893))
	*/
	
	.findall(part(DirID, PartNorms),
		part_direction_norm(direction(DirID), depot(_), part_norms(PartNorms)), 
			PartInfoList);
	
	?depotID(DepotID);
	for(.member(part(DirID,PartNorms),PartInfoList)){
		for(.member([PartNumber, PartNorm], PartNorms)){
			if (PartNorm > 0){
				!get_p_name(DepotID, DirID, PartNumber, PartID);
				+sink(id(PartID),need(PartNorm));
				//.print(sink(id(PartID),need(PartNorm)));
			}
		}
	}
	
	.print("findall started...");
	.findall(TeamID, part_direction_norm(direction(DirID), _, _)
		 & team_allowed(team(TeamID),direction(DirID)) 
		 & team(id(TeamID), _, Mode, State), TeamList);
	.print("findall finished");
	
	.print(TeamList);
	
	!set_max_buff;
	
	for (.member(TeamID,TeamList)){
		?team(id(TeamID), _, Mode, State);
		+source(id(TeamID),exceed(1));
		.print(source(id(TeamID),exceed(1)));
		
		!count_cost_by_direction(TeamID, CostTeamDir);
		for(.member(part(DirID,PartNorms),PartInfoList)){
			for(.member([PartNumber, PartNorm], PartNorms)){
				if(PartNorm > 0){
					!get_p_name(DirID, PartNumber, PartID);
					!count_cost_partN(TeamID, PartNumber, Mode, State, CostTeamPart);
					+crosscost(source(TeamID), sink(PartID), 
						cost(CostTeamPart + CostTeamDir));
				}
			}
		}
	}
.

+!add_fake_source <-
	.findall(PartNorm, sink(id(_),need(PartNorm)) & PartNorm > 0, NormListSpec);
	TotalNorm = math.sum(NormListSpec);
	.findall(TeamID, source(id(TeamID),_), TeamListSpec);
	.length(TeamListSpec,TotalTeams);
	TeamExcess = TotalTeams - TotalNorm;
	if(TeamExcess >= 0) {
		?infinity(Inf);
		?fakepart(Fakepart);
		+sink(id(Fakepart),need(TeamExcess+1));
		for(source(id(TeamID),_)) {
			+crosscost(source(TeamID), sink(Fakepart), cost(Inf));
		}
	}
.


+!get_p_name(DepotID, DirID, PartNumber, PartID)
<-
	.concat("dep", DepotID, "_dir", DirID, "_", PartNumber, PartIDSTR);
	.term2string(PartID, PartIDSTR);
.


+!count_cost_partN(TeamID, PartNumber, Mode, State, CostTeamPart)
<-
	if (State = state(work_nights(NightsWorked1), _)) {
		NightsWorked = NightsWorked1;
	} else {
		if (State = state(_, work_nights(NightsWorked1), _)){
			NightsWorked = NightsWorked1;
		} else {
			NightsWorked = 0;
		}
	}

	if (Mode = work(will_work(MoreWorkHours), will_rest(RestHours))){
		!calc_fact_add_work(MoreWorkHours, RestHours, NightsWorked,
			FactHours, AddHours);
	} else {
		if (Mode = rest(past_rest(PastRestHours), will_rest(MoreRestHours), _)){
			!calc_fact_add_rest(PastRestHours, MoreRestHours, NightsWorked,
				FactHours, AddHours);
		} else {
			if (Mode = vacation(will_start(TimeStart))){
				!calc_fact_add_vacation(TimeStart, FactHours);
			}
		}
	}
	
	?infinity(Inf);
	if (.ground(FactHours)) {
		FactStartTime = 24 - FactHours;
	} else {
		FactStartTime = Inf;
	}
	
	if (.ground(AddHours)) {
		AddStartTime = 24 - AddHours;
	} else {
		AddStartTime = Inf;
	}
	
	if (team_fact_add(TeamID, _, _)){
		-+team_fact_add(TeamID, FactStartTime, AddStartTime);
	} else {
		+team_fact_add(TeamID, FactStartTime, AddStartTime);
	}
	
	if (PartStartTime > FactStartTime) {
		?const_fact(Const1);
		CostTeamPart = (8 - PartNumber + 1) * Const1;
	} else {
		if (PartStartTime > AddStartTime) {
			?const_add(Const2);
			CostTeamPart = (8 - PartNumber + 1) * Const2;
		} else {
			CostTeamPart = Inf;
		}
	}
	
.


+!set_max_buff
<-
	.findall(Time, buffer(_,time(Time)), TimeArr);
	.max(TimeArr, BufTime);
	-+max_buffer(BufTime);
.


+!calc_fact_add_work(WorkHours, RestHours1, NightsWorked, FactHours, AddHours)
<-
	// work
	// work(will_work(WorkHours)
	// will_rest(RestHours1)

	?min_rest(MinRestHours1);
	?max_buffer(BufTime);
	RestHours = RestHours1 + BufTime;
	MinRestHours = MinRestHours1 + BufTime; 
	
	//?start_plan_hour(StartPlanHour);
	//StartNight = 24 - StartPlanHour;
	//EndNight = (StartNight + 5) mod 24;
	
	?start_time(StartTime);
	!hours_to_end(StartTime, PrevHours);
	
	//FACT
	FreeHours = 24 + PrevHours - WorkHours;  // NB - can be > 24!
	!trunc_hour(24 + PrevHours - WorkHours - RestHours,FactHours);
	
	// ADD
	if (NightsWorked == 2) {
		!get_nonight_hours(FreeHours - MinRestHours,AddHours,AddStart);
	} else {
		!trunc_hour(FreeHours - MinRestHours,AddHours);
	};
.


+!calc_fact_add_rest(PastRestHours, MoreRestHours1, NightsWorked, FactHours, AddHours)
<-
	// past_rest(PastRestHours)
	// will_rest(MoreRestHours1)

	?min_rest(MinRestHours1);
	?max_buffer(BufTime);
	MoreRestHours = MoreRestHours1 + BufTime;
	MinRestHours = MinRestHours1 + BufTime; 
	
	//?start_plan_hour(StartPlanHour);
	//StartNight = 24 - StartPlanHour;
	//EndNight = (StartNight + 5) mod 24;
	
	?start_time(StartTime);
	!hours_to_end(StartTime, PrevHours);

	//FACT
	!trunc_hour(24 + PrevHours - MoreRestHours,FactHours);
	
	// ADD
	MinMoreRestHours = math.max(0,MinRestHours - PastRestHours);
	if (NightsWorked == 2) {
		!get_nonight_hours(24 - MinMoreRestHours,AddHours,AddStart);
	} else {
		AddHours = 24 - MinMoreRestHours;
	};
.


+!calc_fact_add_vacation(TimeStart1, FactHours)
<-
	// vacation(will_start(TimeStart1))

	?max_buffer(BufTime);
	TimeStart = TimeStart1 + BufTime;
	!trunc_hour(24 - TimeStart,FactHours);
.


+!hours_to_end(Hrs,New_Hours)
<-	
	?start_plan_hour(DC);
	
	if (Hrs > DC){
		New_Hours = 3 - ((Hrs - DC) mod 3);
	} else {
		New_Hours = (DC - Hrs) mod 3;
	}
.


+!get_nonight_hours(AH,0,0) : AH <= 0.

+!get_nonight_hours(AvHours,AvHours,24 - AvHours) // planned start recently after night
	: night_interval(_,NE) & (24 - AvHours) < (NE + 4). 
		
+!get_nonight_hours(AvHours,24 - NE, NE) // planned start shortly before night
	: night_interval(NS,NE) & (24 - AvHours) < NE & (24 - AvHours) > NS - 4.
				
+!get_nonight_hours(_,0,0).


+!trunc_hour(Hours,24): Hours >= 24.			
+!trunc_hour(Hours,0): Hours <= 0.
+!trunc_hour(Hours,math.round(Hours*100) * 0.01): Hours > 0 & Hours < 24.


+!count_cost_by_direction(TeamID, CostTeamDir)
<-
	//.print(count_cost_by_direction, " ", TeamID);
	.count(team_allowed(team(TeamID), _), N);
	?const_direction(Const2);
	CostTeamDir = N*Const2;
.


+totals(util(TotU),cost(TotC),steps(TotS)) 
	<-
	.print("Total utility: ",TotU);
	.print("Total cost: ",TotC);
	.print("Total steps: ",TotS);
.


+transportation_streams(Streams)
<-
	+toWorkArr([]);
	
	for(.member(stream(source(Source),sink(Sink),quantity(Quantity)),
		Streams)) {
		
		!get_dirid_partn_worktime(Source, Sink, DirID, PartN, WorkFrom, CFlag);
		?toWorkArr(WorkArr);
		.concat(WorkArr,
			[to_work(id(Source), direction(DirID), work_from(WorkFrom), call_type(CFlag))],
				ToWorkArr);
		-+toWorkArr(ToWorkArr);
	}
	?start_time(ST);
	.print("calculation time: ",(system.time-ST)/1000," s");
	
	?parent(Parent);
	?depotID(DepID);
	.send(Parent,tell,to_work_data([DepID, ToWorkArr]));
.


+!get_dirid_partn_worktime(TeamID, Sink, DirID, PartN, WorkFrom, CFlag)
<-
	parse_string(Sink);
	?parsed(Sink, DirID, PartN);
	?team_fact_add(TeamID, FactStartTime, AddStartTime);
	
	//.print(team_fact_add(TeamID, FactStartTime, AddStartTime));
	
	PartStart = PartN*3;
	if (PartStart > AddStartTime){
		if (PartStart > FactStartTime) {
			WorkFrom = PartStart;
		} else {
			WorkFrom = FactStartTime;
		}
		CFlag = full_rest;
	} else {
		WorkFrom = AddStartTime;
		CFlag = cut_rest;
	}
.

