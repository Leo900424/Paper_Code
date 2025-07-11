import pandas as pd


filename = "raw_data/08_07_"
output = "08_07_"
# 讀取 CSV 檔案
df = pd.read_csv(filename + "data.csv")

df['Beam ID'] = df['Beam ID'].fillna(-1).astype(int)

# 只保留與衛星與 Beam 相關的欄位
df_filtered = df[['Satellite ID', 'Beam ID']].reset_index(drop=True)

# 初始化狀態
results = []
current_sat = None
current_beams = []
access_counter = {}

# 掃描每一筆資料
for idx, row in df_filtered.iterrows():
    sat = row['Satellite ID']
    beam = int(row['Beam ID']) if pd.notna(row['Beam ID']) else -1
    

    # 如果遇到新衛星，視為新的 access
    if sat != current_sat:
        if current_sat is not None:
            results.append({
                'Satellite ID': current_sat,
                'Access Index': access_counter[current_sat],
                'Beam Sequence': current_beams
            })

        current_sat = sat
        access_counter[sat] = access_counter.get(sat, 0) + 1
        current_beams = [beam]
    else:
        # 同一顆衛星，若 beam 改變才記錄
        if beam != current_beams[-1]:
            current_beams.append(beam)

# 儲存最後一筆
results.append({
    'Satellite ID': current_sat,
    'Access Index': access_counter[current_sat],
    'Beam Sequence': current_beams
})

# 建立 DataFrame
access_df = pd.DataFrame(results)

# 計算 beam 數量與切換次數
access_df['Beam Count'] = access_df['Beam Sequence'].apply(len)
access_df['Beam Switches'] = access_df['Beam Sequence'].apply(
    lambda seq: sum(1 for i in range(1, len(seq)) if seq[i] != seq[i-1])
)

# 移除重複 beam（保留第一次出現）
def remove_duplicate_beams_preserve_first(seq):
    seen = set()
    result = []
    for beam in seq:
        if beam not in seen:
            seen.add(beam)
            result.append(beam)
    return result

access_df['Unique Beam Sequence'] = access_df['Beam Sequence'].apply(remove_duplicate_beams_preserve_first)

# 顯示前幾筆結果
print(access_df.head())

access_df.to_excel(output + "beam_sequence_result.xlsx", index=False)