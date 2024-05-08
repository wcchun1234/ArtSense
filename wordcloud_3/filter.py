#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Mar 29 01:23:01 2024

@author: wcchun
"""

import pandas as pd

# Load the CSV file
df = pd.read_csv('/Users/wcchun/cityu/FYP/coding/wordcloud/word_ecg_coordinates.csv')

# Define a list of stop words
stop_words = set([
    # Add your stop words here, this is just an example
    "the", "and", "a", "to", "of", "in", "i", "is", "that", "it", "on", "you", "this", "for", "but", "with", "are", "have", "be",
    "at", "or", "as", "was", "so", "if", "out", "not"
])

# Filter the DataFrame to exclude rows with words in the stop words list
filtered_df = df[~df['word'].str.lower().isin(stop_words)]

# Save the filtered DataFrame to a new CSV file
filtered_df.to_csv('filtered_word_ecg_coordinates.csv', index=False)
