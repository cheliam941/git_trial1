import pandas as pd

data = {
    'name': ['Tom', 'Nick', 'John'],
    'age': [20, 21, 19],
    'gender': ['male', 'female', 'male'],
    'Maths': [80, 50, 61],
    'Physics': [90, 70, 80],
    'Chemistry': [70, 80, 90],
    'English': [65, 73, 23],
    'History': [70, 62, 72]

}

df = pd.DataFrame(data)

dcol = df.columns
new_col = [col for col in dcol if col not in ['name', 'gender', 'age']]
new_df = df[new_col]
# print(new_df)

each_ave = new_df.mean(axis=1)
# print(each_ave)

high_student = df.loc[each_ave == max(each_ave), 'name']
print(high_student)

import sqlite3
import pandas as pd

def get_rate(in_genre):
    conn = sqlite3.connect('fa')
    c = conn.cursor()
    sql = f"""
    select avg(rating) as ave_rating, genre from movies
    left join rating on movies.movie_id = rating.movie_id
    group by genre;
    """
    df = pd.read_sql_query(sql, conn)
    conn.close()
    where_genre = df.index[df['genre'] == in_genre].tolist()
    return df.loc[where_genre, 'ave_rating']


