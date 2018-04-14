# electricityPrediction
Reducing the use of electricity in an area

Introduction
The purpose of the report is to explain the project which is trying to manage demand side flexibility in consumption of electricity in six different household. At present there are very few projects around the world which are concentrating on making demand of electricity in household flexible. This project is trying to explore a simple solution for this problem. To achieve the purpose of the project, R and tableau is used for analysing the dataset and MongoDB is used for Data storage.
Description of the Dataset
The Dataset used for the assignment consists of data related to electricity consumption by appliances in houses. 
•	The Data belongs to six different households 
•	The Data is divided into six different files, each file belonging to one household
•	Each house owns different number of appliances
•	The data provided is for the calendar year 2016 
•	Recorded at one-hour interval
 

Analysis 
The ever-increasing demand of electricity has increased the load on the electricity Grid. Too much of load on the grid can cause complete breakdown. Therefore, it is crucial to manage the demand of electricity especially in the peak seasons. Demand side flexibility is to defer the energy consumption of devices like air conditioning, water heating, and electric vehicle as the usage of these devices are not time dependent, and allow them to use electricity at times when load on the energy grid is less or when there is no shortage.
To perform analysis on the dataset, all the background appliance has to be identified and separated from all other appliances. The consumption of electricity by all the appliances in the six houses is combined to form grid of that area. The power consumption by the background appliance in all the six house is shifted according to the load on the electricity grid. When the load on the grid is high, some of the background appliance will be shifted to time where the load on the electricity grid is low. 
Methodology
Optimization Methods 
There can be many ways in which the electricity consumption of the appliances in the house can be optimised. Some of the optimising techniques are as follows:
•	Mathematical solution 
o	Method: Dividing the value of few background appliance into half when the load on the grid is high. The value removed then can be added to other timing when grid load is less 
o	Problem: Complex mathematical calculation has to be used for achieving the result  
•	Shifting/ moving the values 
o	Method: Shifting/Moving the whole-time line of the background appliance which consumes highest electricity when the load on the grid is high.
o	Problem: The outcome of the optimization was not promising
•	Swapping the values:
o	Method: Swap the value of few background appliances when the load on the grid is high with the values of the appliances when the load on the grid is low 
o	Advantages: The swap is only for an hour, after which the appliance can continue its normal consumption. The outcome was promising. Therefore, this method has been used for optimization. 

Algorithm: Swapping the values
Step 1: Loop over the data set in the sequence of 24 (1-day data)
Step i: Select the maximum value of grid and the time with respect to it in the sequence 
Step ii: If the value is greater than 4 
	Step a: Select three appliances with highest electricity consumption on that time 
	Step b: Select three minimum time in the sequence 
Step c: Loop over the maximum selected appliance and minimum selected time 
Step d: Swap the value of the appliance with its corresponding value in minimum time 
Step e: subtract and add the value form the respective grid 
Step f: check if the max grid value is above 2 
Step g: continue to swap the appliance 
Step I: else break
Step iii: else break


Conclusion 
The algorithm used for the optimisation is successfully able to reduce the consumption of energy to almost 50%. The maximum consumption before optimization is 14.70705 and after optimization the maximum consumption dropped to the value of 7.752939. This project demonstrates that it is possible to stabilize the demand of energy from each house by regulating the usage of appliances which are not time dependent. 
However, the customer cannot be provided with specific suggestion to change the usage time of the appliance as the timing to which the appliance usage will be shifted is not fixed and could change every day. But, this algorithm can be used in homes through devices which use machine learning to reduce the consumption by the appliances.
