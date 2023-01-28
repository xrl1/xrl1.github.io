---
title: 'Creating Real-World AI Models by Newbies With ChatGPT'
date: '2023-01-28T11:21:07+02:00'
categories: [Machine Learning]
tags: ['Machine Learning', 'AI', 'ChatGPT', 'geo-location', 'model', 'k-NN', 'coordinates', 'geonames', 'newbies']
img_path: /assets/img/
---
After ChatGPT came out, I challenged it greatly - with riddles, general questions, and lots of code-generation tasks.  
It stood firm for most of my dares, and even when it didn't, it still pretended to know the answer and provided a detailed wrong explanation, the same behavior as many of my coworkers.  
After a while, it became a major tool in my arsenal, to the extent that whenever I open a new tab in chrome and type 'c', the browser suggests `chat.openai.com/chat` even before `calendar.google.com/...`


## The Task
Even though I'm not a data scientist, I have had some experience training basic machine learning models before. This time, I wanted to get into the shoes of a machine learning newbie - with only basic Machine learning knowledge and some python pandas experience.  
The goal is to see how ChatGPT can create a real Machine Learning model from scratch - with as little intervention on my side as possible, especially in the data collection process (known as the most challenging part of training usually).  
I wanted to find a fun challenge with enough data online, but the data shouldn't be machine-learning-ready. So I started browsing some GitHub [awesome](https://github.com/topics/awesome-list) lists to get inspiration. When I stumbled upon multiple geolocation projects, I got an idea: Train a model to predict in which country a certain coordinate is!

## Hey ChatGPT
Let's fire up that chatGPT and ask him for help!  

>![Me](avatar_small.jpg){: .left } 
>Hey, chatGPT, I want to create a small AI program, and I don't want to work hard on my own. I want to write a small program that receives two coordinates as input and predicts in which country they are. Are you up for the challenge?

>![ChatGPT](chatGPT.jpeg){: .left }
>Yes, I can help you create a small AI program that predicts the country based on given coordinates. However, keep in mind that this task would require a dataset of coordinates and corresponding countries. Without this dataset, the model cannot be trained. Additionally, it would be helpful if you could provide more details about the specific requirements and constraints of the program.

It is up for the challenge and understands the mission before us well enough! 

## The Dataset
Hopefully, a dataset will be available and easily downloadable.

>![Me](avatar_small.jpg){: .left } 
>Which dataset can I use?

<br />
>![ChatGPT](chatGPT.jpeg){: .left }
>There are a few datasets that you can use for this task:
>
>1.  GeoNames dataset: This dataset provides information about various geographical features such as cities, countries, and administrative divisions. It includes information such as coordinates, population, and time zone. The dataset can be found here: [http://download.geonames.org/export/dump/](http://download.geonames.org/export/dump/)
>
> 2.  Natural Earth dataset: This dataset provides detailed information about the world's countries, including their boundaries, coastlines, and other geographical features. The dataset includes information such as coordinates, population, and GDP. The dataset can be found here: [http://www.naturalearthdata.com/downloads/](http://www.naturalearthdata.com/downloads/)
>    
>3.  Open Street Map dataset: This dataset is a collaborative project to create a free editable map of the world. It includes information such as coordinates, roads, buildings, and land use. The dataset can be found here: [https://www.openstreetmap.org/export#map=5/51.500/-0.100](https://www.openstreetmap.org/export#map=5/51.500/-0.100)  
>
>You can use the above datasets or others that you might find, but make sure the dataset includes the information you need to train your model.

Cool,  from looking briefly at the three options, Natural Earth dataset looks like a win because it has border coordinates, but from a glance in the downloads section, it isn't the easiest choice: the data isn't in a simple CSV format, and it will be another challenge to explain to the model the concept of a "border" that separates labels.

For simplicity, we prefer a dataset with multiple coordinates and the corresponding country in order for the model to learn something like "Oh, I see that those coordinates are mathematically near each other, and they are all called country X, so probably another close coordinate will also be in country X." 
So let's just say that in the newbies' shoes, we chose the first option, as an unknowledgeable newbie may do.
>![Me](avatar_small.jpg){: .left } 
>Okay, let's try the first dataset! I want to download allCountries.zip, and create a DataFrame with latitude, longitude, and country columns.

>![ChatGPT](chatGPT.jpeg){: .left }
>Sure, you can download the allCountries.zip file from the GeoNames website, and then extract the data to a csv file. Once you have the data in a csv file, you can use a library such as Pandas to create a DataFrame. Here is some sample code to get you started:

```python
import pandas as pd

# read the data from the csv file
data = pd.read_csv("allCountries.txt", sep='\t', header=None,
                   names=["country","name","asciiname","alternatenames","latitude","longitude","feature_class","feature_code","country_code","cc2","admin1_code","admin2_code","admin3_code","admin4_code","population","elevation","dem","timezone","modification_date"])
                   
# select the columns of interest
data = data[["latitude","longitude","country"]]

# display the first 5 rows of the DataFrame
print(data.head())
```
 ... (*Explanation redacted*)

>[DataFrame](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.html) is a commonly used data structure in data science. In such projects, it is also comfortable to work inside some python notebook - a web wrapper around a python interpreter that lets you execute code snippets and visualize the output nicely.  
{: .prompt-tip }

I'll fire up a [jupyter notebook](https://jupyter.org/), and execute the code in a cell. This is the output:
```   
   latitude  longitude  country
0  42.64991    1.53335  2986043
1  42.58765    1.74028  2994701
2  42.61203    1.47364  3007683
3  42.52535    1.73343  3017832
4  42.52915    1.73362  3017833
```
It worked!  
The latitude and longitude look good, but the country is wrong.  
According to the `readme.txt` under the GeoNames link, the first column in the CSV is actually "geonameid" and not "country". We will let this small mistake pass by and modify the `read_csv` function call to use "country_code" instead, as "country".
```python
data = pd.read_csv("allCountries.txt", sep='\t', header=None,
                   names=["geonameid","name","asciiname","alternatenames","latitude","longitude","feature_class","feature_code","country","cc2","admin1_code","admin2_code","admin3_code","admin4_code","population","elevation","dem","timezone","modification_date"])
```
After re-executing the code, we got the following:
```   
   latitude  longitude country
0  42.64991    1.53335      AD
1  42.58765    1.74028      AD
2  42.61203    1.47364      AD
3  42.52535    1.73343      AD
4  42.52915    1.73362      AD
```
And it works!
AD country code stands for Andora, but when dropping the coordinates in Google Maps, we can see that some are indeed in Andora, but others are sliding over the border into France.  
I used `data.sample(10)` to check other coordinates further, and they were correctly labeled.  
Generally, the data is accurate with small around-the-border errors, but we will take the errors into consideration later.

## Model Training
Let's create some Artificial Intelligence!
>![Me](avatar_small.jpg){: .left } 
>Now, please write a python script to create a prediction model from the DataFrame above!

<br />
>![ChatGPT](chatGPT.jpeg){: .left }
>Sure, here is some sample code to create a simple prediction model using the latitude and longitude as input and the country as the output:

```python
from sklearn.model_selection import train_test_split
from sklearn.neighbors import KNeighborsClassifier

# Split the data into training and test sets
X = data[["latitude", "longitude"]]
y = data["country"]
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Create a KNN classifier with 5 nearest neighbors
knn = KNeighborsClassifier(n_neighbors=5)

# Fit the classifier to the training data
knn.fit(X_train, y_train)

# Print the accuracy of the model on the test data
print("Accuracy:", knn.score(X_test, y_test))
```
>This code will use K-Nearest Neighbors (KNN) algorithm to predict the country based on the given coordinates. The KNN algorithm is a simple algorithm that classifies an input based on the majority class of its k nearest neighbors.  
>In this example, the data is split into a training set and a test set with a 80-20 ratio. Then the KNN classifier is trained with the training set and the accuracy of the model is measured with the test set.  
>Keep in mind that this is a simple example and the accuracy of the model might not be high. You can try experimenting with different algorithms and different values for k to see if you can improve the accuracy of the model.  
>...

The code is pretty standard, and the model ChatGPT chose for the task is K-NN, which, as explained, will try to predict a coordinate based on neighbors. If we stretch the truth a little, we can say that the country will be predicted based on "closeness" to other cities - if the 5 closest cities of a given location are all in Japan, the location is probably in Japan as well.  Sounds very logical and fit for our task 😁

Executing the above throws an exception `ValueError: Input contains NaN`. I asked ChatGPT if it understood the error, and of course, it provided a long and exhaustive response. To keep this long post a little shorter, I'll TL;DR:  
There were some empty values in the DataFrame. We can either try to fill or ignore them. As filling them out takes more work, we will check out how much data we will lose:
```python
print(data.shape)
print(data.isnull().sum())

(12363388, 3)
latitude         0
longitude        0
country      14551
```
There are 12363388 countries in the dataset, from which 14551 are missing. It is only 0.1% of the data. Therefore we will just discard the rows with empty countries:
```python
data = data.dropna()
```
Re-executing the K-NN training now succeeds; what accuracy do we get?
```
Accuracy: 0.9971058010307041
```
Amazing! 99.7% accuracy on the first try!

## Re-evaluation
The astonishing first-try accuracy metric isn't satisfying enough: remember earlier some errors in the data, and because it is based on cities/other locations, we can say the dataset has some prejudice, and therefore I want to re-evaluate the accuracy with an external and random dataset.

>![Me](avatar_small.jpg){: .left } 
>Okay, now let's create another dataset to further evaluate the accuracy of the KNN model. Let's select 10,000 random coordinates on a map and send them to some geolocation REST-API. Please write a python script for the task. Use `tqdm` to display progress and use try-except around fail-prone parts.

>![ChatGPT](chatGPT.jpeg){: .left }
>Sure, here's some sample code that generates 10,000 random coordinates and sends them to a geolocation API to get the country information:

```python
import random
import requests
from tqdm import tqdm

# Set the number of coordinates to generate
num_coordinates = 10000

# Create an empty list to store the results
results = []

# Use tqdm to display progress
for i in tqdm(range(num_coordinates)):
    # Generate a random latitude and longitude
    lat = random.uniform(-90, 90)
    lon = random.uniform(-180, 180)

    # Send a request to the geolocation API
    try:
        response = requests.get(f"https://api.opencagedata.com/geocode/v1/json?q={lat}+{lon}&key=YOUR_API_KEY")
        data = response.json()
        results.append((lat, lon, data['results'][0]['components']['country']))
    except:
        results.append((lat, lon, 'NA'))

# Create a DataFrame from the results
import pandas as pd
df_new = pd.DataFrame(results, columns=["latitude", "longitude", "country"])
```
>In this code, I am using the OpenCage Geocoding API to get the country information from the coordinates. You need to replace `YOUR_API_KEY` with your API key to get access to the API. You can sign up for a free API key on the OpenCage website

I followed the instructions, and modified the code with the correct API_KEY, `num_coordinates` to 2500 because this is the amount of free API requests toOpenCage, and saved the result to csv.
A sample of the result:
```
       latitude   longitude country
80   -67.057900  151.629167      NA
694   61.930620  -66.216010  Canada
1667   7.481893 -155.699348      NA
1669 -70.585375  -24.491804      NA
2203  70.407657   28.774544  Norway
```
As we can see, there are a lot of "NA" errors - we are left with 30% of the data. The world is really mostly water.  
Also, the country is a full name, but the original dataset has a country code, so with the help of chatGPT and some small modifications, I translated the country to country code using [countryInfo.txt](https://download.geonames.org/export/dump/countryInfo.txt), and run the predication on the newly-collected data:
```python
from sklearn.metrics import accuracy_score

# predict the country of the coordinates in the new dataframe
predictions = knn.predict(df_new[["latitude", "longitude"]])

# calculate the accuracy of the model on the new dataframe
accuracy = accuracy_score(df_new["country"], predictions)
print(f"Model accuracy: {accuracy}")
```
The result is:
`Model accuracy: 0.986764705882353.`  
Amazing! A little worse than the previous 99.7% precision, but still a staggering accuracy for so little effort put into the model.

Exploring the misses is interesting:
```python
df_new["predictions"] = predictions
print(df_new.loc[df_new["country"] != df_new["predictions"]])
```
```
       latitude   longitude country predictions
336  -18.241242   16.706105      NA          AO
931  -25.104256   22.713657      BW          ZA
958  -23.995538   17.280858      NA          ZA
1348  -9.672760 -138.965349      FR          PF
1457 -25.492231   16.244680      NA          ZA
1674  25.880065  -14.315396      MA          EH
1991  10.419924   23.470560      SD          CF
1999 -49.213029  -73.137265      AR          CL
2160 -22.501809   16.604622      NA          BW
```
They are mostly near the borders of African countries, where the original dataset might have some errors or lacks data 😄  
Another error is somewhat funny and political: French Polynesia is a country in GeoNames, but it is classified as France in OpenCage.  

## Conclusion
ChatGPT is a tremendous technology. With little input and just small modifications, we created a highly accurate machine-learning program that predicts real-world geolocations.

Here is the [jupyter notebook](/assets/country_predictor.ipynb) and the [full conversation](https://shareg.pt/7zLivmp).

Disclosure: to be honest, this is my second conversation for the same task. The first time I talked with ChatGPT, I tried a smaller dataset from the same source (cities500.zip). More dataset corrections were needed, and the first model training code it offered was [LogisticRegression](https://en.wikipedia.org/wiki/Logistic_regression), which resulted in 51% accuracy.  
As a result, ChatGPT offered to try different "solvers" (which gave ~65% accuracy), and other algorithms, including Random Forest and K-NN, resulting in 93% and 92% accuracy.

\* I really considered addressing ChatGPT as "He" instead of "it" in this post