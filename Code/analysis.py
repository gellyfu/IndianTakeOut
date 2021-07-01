import pandas as pd
import numpy as np

import statsmodels.api as sm
from stargazer.stargazer import Stargazer

import matplotlib.pyplot as plt
from wordcloud import WordCloud, STOPWORDS

# read data
data = pd.read_csv('Indian Merged Data.csv')

# extract sub data set and compute total order price
subData = data[['Order_Number', 'Date', 'Quantity', 'Product_Price', 'meanTemp', 'Rain', 'Sun']].copy()
subData['Order_Price'] = subData['Quantity'] * subData['Product_Price']
subData = subData.groupby(['Order_Number', 'Date', 'meanTemp', 'Rain', 'Sun'])['Order_Price'].sum().reset_index()
subData['Month'] = subData['Date'] % 100 # extract month from date (fixed effects)

# aggregate by year-month (date): total order price, number of orders, average order price
dataAgg = subData.groupby(['Date', 'meanTemp', 'Rain', 'Sun', 'Month'])['Order_Price'].sum().reset_index()
dataQuantity = subData.groupby(['Date', 'meanTemp', 'Rain', 'Sun', 'Month'])['Order_Price'].count().reset_index()
dataPrice = subData.groupby(['Date', 'meanTemp', 'Rain', 'Sun', 'Month'])['Order_Price'].mean().reset_index()

# summary statistics to excel
writer = pd.ExcelWriter('Summary Statistics.xlsx', engine='xlsxwriter')
dataAgg.describe().to_excel(writer, sheet_name='Sheet1')
dataQuantity.describe().to_excel(writer, sheet_name='Sheet2')
dataPrice.describe().to_excel(writer, sheet_name='Sheet3')
writer.save()

# custom regression function
def customReg(data, Xvar, Yvar, fixed=None):
    Xvar.append(fixed)
    X = data[Xvar]
    X = pd.get_dummies(X, prefix=[fixed], columns=[fixed], drop_first=True)
    X = sm.add_constant(X)
    Y = data[Yvar]
    return sm.OLS(Y, X).fit()

# regressions
modelAgg = customReg(dataAgg, ['meanTemp', 'Rain', 'Sun'], 'Order_Price', 'Month')
modelQuantity = customReg(dataQuantity, ['meanTemp', 'Rain', 'Sun'], 'Order_Price', 'Month')
modelPrice = customReg(dataPrice, ['meanTemp', 'Rain', 'Sun'], 'Order_Price', 'Month')

# format regressions
allModels = Stargazer([modelQuantity, modelPrice, modelAgg])
latex = allModels.render_latex()

# word cloud
wordcloud = WordCloud(width=800, height=800,
                         random_state=1,
                         background_color='white',
                         colormap='RdYlGn',
                         stopwords=STOPWORDS).generate(data['Item_Name'].to_string())
plot = plt.figure(1)
plt.imshow(wordcloud, interpolation='bilinear')
plt.axis("off")
plt.savefig('Word Cloud.jpg')