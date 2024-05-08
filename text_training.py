#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Mar 26 17:56:14 2024

@author: wcchun
"""

import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
from nltk.corpus import stopwords
import nltk
import numpy as np

# Ensure stopwords are downloaded
nltk.download('stopwords')
stop_words = list(stopwords.words('english'))

# Function to load CSV and return a DataFrame
def load_csv(file_path):
    df = pd.read_csv(file_path, header=None)
    df = df.apply(pd.to_numeric, errors='coerce').dropna()
    return df

# Specified file paths
text_data_path = '/Users/wcchun/cityu/FYP/coding/data.csv'
ecg_data_paths = [
    '/Users/wcchun/cityu/FYP/coding/ECG_data/ecg_2021-11-23.csv',
    '/Users/wcchun/cityu/FYP/coding/ECG_data/ecg_2021-11-24.csv',
    '/Users/wcchun/cityu/FYP/coding/ECG_data/ecg_2022-02-22.csv',
    '/Users/wcchun/cityu/FYP/coding/ECG_data/ecg_2022-02-27.csv',
    '/Users/wcchun/cityu/FYP/coding/ECG_data/ecg_2022-03-16.csv',
    '/Users/wcchun/cityu/FYP/coding/ECG_data/ecg_2022-04-03.csv',
    '/Users/wcchun/cityu/FYP/coding/ECG_data/ecg_2023-03-31.csv',
    '/Users/wcchun/cityu/FYP/coding/ECG_data/ecg_2023-04-01.csv',
    '/Users/wcchun/cityu/FYP/coding/ECG_data/ecg_2023-09-22.csv'
]

# Load and combine ECG data
ecg_data_frames = [load_csv(path) for path in ecg_data_paths]
ecg_combined_df = pd.concat(ecg_data_frames, ignore_index=True)

# Load text data, ensuring non-numeric rows are handled
text_df = pd.read_csv(text_data_path, header=None, names=['text'])
text_df['text'] = text_df['text'].fillna('').astype(str)

# Process text data with TF-IDF, removing stop words and numeric-only words
vectorizer = TfidfVectorizer(stop_words=stop_words, token_pattern=r'(?u)\b[A-Za-z]+\b')
text_features = vectorizer.fit_transform(text_df['text']).toarray()

# Standardize ECG data
scaler = StandardScaler()
ecg_features = scaler.fit_transform(ecg_combined_df)

# Ensure the number of samples matches
min_samples = min(text_features.shape[0], ecg_features.shape[0])
text_features = text_features[:min_samples]
ecg_features = ecg_features[:min_samples]

# Concatenate text and ECG features
combined_features = np.concatenate((text_features, ecg_features), axis=1)

# Apply PCA to reduce dimensions to 3D
pca_combined = PCA(n_components=3)
combined_features_pca = pca_combined.fit_transform(combined_features)

# Extract words excluding purely numeric ones
words = vectorizer.get_feature_names_out()

# Create DataFrame for words and their 3D coordinates
word_coordinates = pd.DataFrame(combined_features_pca[:len(words)], columns=['x', 'y', 'z'])
word_coordinates['word'] = words

# Export the word coordinates to a CSV file
output_file_path = '/Users/wcchun/cityu/FYP/coding/word_ecg_coordinates.csv'
word_coordinates.to_csv(output_file_path, index=False)
