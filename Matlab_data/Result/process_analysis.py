
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

def process_strategy_file(filepath):
    df_raw = pd.read_excel(filepath, header=None)
    ue_header_row = df_raw[df_raw.iloc[:, 0] == "UEName"].index
    if len(ue_header_row) == 0:
        raise ValueError(f"'UEName' row not found in {filepath}")
    start_row = ue_header_row[0] + 1

    df = df_raw.iloc[start_row:].copy()
    df.columns = ['UE', 'BeamPath', 'SwitchedBeams', 'SwitchCount',
                  'BeamCount', 'NormalizedFLSI', 'ConsecFLSICount',
                  'TransitionCount', 'ConsecutiveFLSIRatio']
    df = df.reset_index(drop=True)

    df['SwitchCount'] = pd.to_numeric(df['SwitchCount'], errors='coerce')
    df['BeamCount'] = pd.to_numeric(df['BeamCount'], errors='coerce')
    df['NormalizedFLSI'] = pd.to_numeric(df['NormalizedFLSI'], errors='coerce')
    df['NormalizedFLSI'] = df['NormalizedFLSI'].fillna(0)
    return df

def main(input_folder, output_pdf):
    strategy_results = {}
    for filename in os.listdir(input_folder):
        if filename.endswith(".xlsx"):
            strategy_name = os.path.splitext(filename)[0].replace("ue_switch_summary_strategy_", "")
            filepath = os.path.join(input_folder, filename)
            df_processed = process_strategy_file(filepath)
            strategy_results[strategy_name] = df_processed

    # === CDF 合併圖（加入 marker） ===
    line_configs = [
        {'color': '#D55E00', 'linestyle': '--', 'marker': 's'},      # 橘紅 - 虛線方塊
        {'color': '#009E73', 'linestyle': '-.', 'marker': '^'},      # 綠 - 點虛線三角
        {'color': '#F0E442', 'linestyle': ':', 'marker': 'D'},       # 黃 - 點線菱形
        {'color': '#56B4E9', 'linestyle': (0, (8, 4)), 'marker': 'x'}, # 淺藍 - 長虛線交叉
        {'color': '#E69F00', 'linestyle': (0, (5, 2, 1, 2)), 'marker': '*'}, # 金橙 - 複合線星
        {'color': '#0072B2', 'linestyle': '-', 'marker': 'o'},       # 藍 - 實線圓點
        {'color': '#000000', 'linestyle': '-', 'marker': '+'},       # 黑 - 實線加號
        {'color': '#CC79A7', 'linestyle': '--', 'marker': 'v'},      # 紫 - 虛線倒三角
    ]

    plt.figure(figsize=(12, 7), dpi=300)
    for idx, (strategy, df) in enumerate(sorted(strategy_results.items())):
        values_sorted = np.sort(df["NormalizedFLSI"].dropna().values)
        cdf = np.arange(1, len(values_sorted) + 1) / len(values_sorted)

        config = line_configs[idx % len(line_configs)]

        plt.plot(
            values_sorted, cdf,
            label=strategy,
            linestyle=config['linestyle'],
            color=config['color'],
            marker=config['marker'],
            markevery=max(len(values_sorted)//15, 1),
            markersize=5,
            linewidth=2.5,
            drawstyle='steps-post'
        )

    plt.xlabel("Normalized FLSI", fontsize=16, fontweight='bold')
    plt.ylabel("CDF", fontsize=16, fontweight='bold')
    # plt.title("CDF Comparison of Normalized FLSI", fontsize=28, fontweight='bold')
    plt.xticks(fontsize=16)
    plt.yticks(fontsize=16)
    plt.grid(True)
    plt.xlim(0, 0.6)
    plt.ylim(0, 1.0)
    plt.legend(
        fontsize=12,
        loc='center left',
        bbox_to_anchor=(1, 0.5),
        title="Strategies",
        title_fontsize=13,
        frameon=False
    )
    plt.tight_layout()
    plt.savefig(output_pdf, bbox_inches='tight')
    print(f"✅ Combined plot saved to: {output_pdf}")

    # === 每個策略個別圖 ===
    for strategy, df in strategy_results.items():
        values_sorted = np.sort(df["NormalizedFLSI"].dropna().values)
        cdf = np.arange(1, len(values_sorted) + 1) / len(values_sorted)

        plt.figure(figsize=(10, 6), dpi=300)
        plt.plot(values_sorted, cdf, linestyle='-', color='black', linewidth=2.2, drawstyle='steps-post')
        plt.xlim(0, 0.6)
        plt.ylim(0, 1)
        plt.xlabel("Normalized FLSI", fontsize=26, fontweight='bold')
        plt.ylabel("CDF", fontsize=26, fontweight='bold')
        # plt.title(f"Normalized FLSI CDF - {strategy}", fontsize=28, fontweight='bold')
        plt.xticks(fontsize=26)
        plt.yticks(fontsize=26)
        plt.grid(True)
        plt.tight_layout()
        single_plot_path = os.path.join(input_folder, f"{strategy}_cdf.pdf")
        plt.savefig(single_plot_path, bbox_inches='tight')
        plt.close()
        print(f"📄 Per-strategy plot saved to: {single_plot_path}")

    # === 分組柱狀圖（策略為 X 軸，條紋 + 色彩） ===
    flsi_dist = {}
    for strategy, df in strategy_results.items():
        value_counts = df['SwitchCount'].value_counts().sort_index()
        flsi_dist[strategy] = value_counts

    flsi_df = pd.DataFrame(flsi_dist).fillna(0).astype(int).T  # 策略為列
    
    desired_order = ['inner_to_outer', 'outer_to_inner', 'random', 'freqBased', 'mobility', 'topoSorted']
    flsi_df = flsi_df.loc[desired_order]

    # 自訂顏色與條紋樣式
    custom_colors = [
        '#d9d2c4', '#b0b8a3', '#808c9b', '#4e545e',
        '#a89a8e', '#8c9b7a', '#6c7a89', '#3b3f45'
    ]
    hatches = ['', '', '-', '/', '\\', '|', '+', 'x', '.', '*']

    # 畫每個群組
    fig, ax = plt.subplots(figsize=(12, 6))
    width = 0.15
    x = np.arange(len(flsi_df.index))  # 策略數

    for i, count in enumerate(flsi_df.columns):
        values = flsi_df[count].values
        ax.bar(
            x + i * width, values,
            width=width,
            color=custom_colors[i % len(custom_colors)],
            hatch=hatches[i % len(hatches)],
            edgecolor='black',
            label=f'FLSI={count}'
        )
        # 加上小數量標示（<100）
        for j, val in enumerate(values):
            if count >= 2:
                xpos = x[j] + i * width
                ax.text(xpos, val + 5, str(val), ha='center', va='bottom',
                        fontsize=8, rotation=0)

    # 美化設定
    ax.set_xticks(x + width * (len(flsi_df.columns) - 1) / 2)
    ax.set_xticklabels(flsi_df.index)
    ax.set_xlabel("Strategy", fontsize=16, fontweight='bold')
    ax.set_ylabel("Number of UEs", fontsize=16, fontweight='bold')
    # ax.set_title("UE Distribution by FLSI Count per Strategy", fontsize=16, fontweight='bold')
    ax.tick_params(axis='both', labelsize=15)  # ✅ 改刻度字體
    ax.legend(title="FLSI Count", fontsize=12)
    ax.grid(True, axis='y')
    plt.tight_layout()

    # 儲存圖表
    bar_output_path = os.path.join(input_folder, "flsi_distribution_by_strategy.pdf")
    plt.savefig(bar_output_path, bbox_inches='tight')
    print(f"📊 Grouped bar chart with hatches saved to: {bar_output_path}")
    
    # === 分組柱狀圖（策略為 X 軸，Consecutive FLSI Count） ===
    consec_flsi_dist = {}
    for strategy, df in strategy_results.items():
        value_counts = df['ConsecFLSICount'].value_counts().sort_index()
        consec_flsi_dist[strategy] = value_counts

    consec_flsi_df = pd.DataFrame(consec_flsi_dist).fillna(0).astype(int).T
    consec_flsi_df = consec_flsi_df.loc[desired_order]  # 使用相同順序

    # 畫圖
    fig, ax = plt.subplots(figsize=(12, 6))
    width = 0.15
    x = np.arange(len(consec_flsi_df.index))

    for i, count in enumerate(consec_flsi_df.columns):
        values = consec_flsi_df[count].values
        ax.bar(
            x + i * width, values,
            width=width,
            color=custom_colors[i % len(custom_colors)],
            hatch=hatches[i % len(hatches)],
            edgecolor='black',
            label=f'ConFLSI={count}'
        )
        for j, val in enumerate(values):
            if count >= 1:
                xpos = x[j] + i * width
                ax.text(xpos, val + 5, str(val), ha='center', va='bottom',
                        fontsize=8, rotation=0)

    ax.set_xticks(x + width * (len(consec_flsi_df.columns) - 1) / 2)
    ax.set_xticklabels(consec_flsi_df.index)
    ax.set_xlabel("Strategy", fontsize=16, fontweight='bold')
    ax.set_ylabel("Number of UEs", fontsize=16, fontweight='bold')
    # ax.set_title("UE Distribution by ConFLSI Count", fontsize=16, fontweight='bold')
    ax.tick_params(axis='both', labelsize=15)
    ax.legend(
        title="ConFLSI Count",
        title_fontsize=10,
        fontsize=9,
        loc='upper right',
        frameon=False,
        markerscale=0.8,
        handlelength=1.5,
        borderpad=0.3,
        labelspacing=0.3,
        handletextpad=0.5
    )
    ax.grid(True, axis='y')
    plt.tight_layout()

    bar_output_path2 = os.path.join(input_folder, "consec_flsi_distribution_by_strategy.pdf")
    plt.savefig(bar_output_path2, bbox_inches='tight')
    print(f"📊 Grouped bar chart (Consec FLSI) saved to: {bar_output_path2}")
    
def analyze_itri_versions(input_folder, output_prefix="itri_topoSorted"):
    def process_strategy_file(filepath):
        df_raw = pd.read_excel(filepath, header=None)
        ue_header_row = df_raw[df_raw.iloc[:, 0] == "UEName"].index
        if len(ue_header_row) == 0:
            raise ValueError(f"'UEName' row not found in {filepath}")
        start_row = ue_header_row[0] + 1

        df = df_raw.iloc[start_row:].copy()
        df.columns = ['UE', 'BeamPath', 'SwitchedBeams', 'SwitchCount',
                      'BeamCount', 'NormalizedFLSI', 'ConsecFLSICount',
                      'TransitionCount', 'ConsecutiveFLSIRatio']
        df = df.reset_index(drop=True)

        df['SwitchCount'] = pd.to_numeric(df['SwitchCount'], errors='coerce')
        df['NormalizedFLSI'] = pd.to_numeric(df['NormalizedFLSI'], errors='coerce').fillna(0)
        df['ConsecFLSICount'] = pd.to_numeric(df['ConsecFLSICount'], errors='coerce').fillna(0)
        return df

    # 讀取檔案
    all_versions = {}
    for filename in os.listdir(input_folder):
        if filename.endswith(".xlsx") and "topoSorted_ITRI" in filename:
            version = filename.split("topoSorted_ITRI_")[-1].replace(".xlsx", "")
            filepath = os.path.join(input_folder, filename)
            df = process_strategy_file(filepath)
            all_versions[version] = df

    # 畫 CDF
    plt.figure(figsize=(12, 7), dpi=300)
    for version, df in sorted(all_versions.items()):
        values_sorted = np.sort(df["NormalizedFLSI"].dropna().values)
        cdf = np.arange(1, len(values_sorted) + 1) / len(values_sorted)
        plt.plot(values_sorted, cdf, label=version, linewidth=2.5, drawstyle='steps-post')

    plt.xlabel("Normalized FLSI", fontsize=20, fontweight='bold')
    plt.ylabel("CDF", fontsize=20, fontweight='bold')
    # plt.title("TopoSorted - Normalized FLSI CDF (ITRI Traces)", fontsize=24, fontweight='bold')
    plt.xticks(fontsize=20)
    plt.yticks(fontsize=20)
    plt.grid(True)
    plt.legend(title="ITRI Version", fontsize=14)
    plt.tight_layout()
    cdf_path = os.path.join(input_folder, f"{output_prefix}_cdf.pdf")
    plt.savefig(cdf_path)
    print(f"✅ CDF saved to: {cdf_path}")
    plt.close()

    # FLSI Count bar chart（套用條紋、色彩樣式）
    flsi_dist = {}
    for version, df in all_versions.items():
        counts = df['SwitchCount'].value_counts().sort_index()
        flsi_dist[version] = counts
    flsi_df = pd.DataFrame(flsi_dist).fillna(0).astype(int).T

    custom_colors = ['#d9d2c4', '#b0b8a3', '#808c9b', '#4e545e', '#a89a8e', '#8c9b7a', '#6c7a89', '#3b3f45']
    hatches = ['', '', '-', '/', '\\', '|', '+', 'x', '.', '*']


    fig, ax = plt.subplots(figsize=(12, 6))
    width = 0.15
    x = np.arange(len(flsi_df.index))

    for i, count in enumerate(flsi_df.columns):
        values = flsi_df[count].values
        ax.bar(
            x + i * width, values,
            width=width,
            color=custom_colors[i % len(custom_colors)],
            hatch=hatches[i % len(hatches)],
            edgecolor='black',
            label=f'FLSI={count}'
        )
        # 加上小數量標示（<100）
        for j, val in enumerate(values):
            if count >= 2:
                xpos = x[j] + i * width
                ax.text(xpos, val + 5, str(val), ha='center', va='bottom',
                        fontsize=8, rotation=0)

    ax.set_xticks(x + width * (len(flsi_df.columns) - 1) / 2)
    ax.set_xticklabels(flsi_df.index)
    ax.set_xlabel("ITRI Version", fontsize=16, fontweight='bold')
    ax.set_ylabel("Number of UEs", fontsize=16, fontweight='bold')
    # ax.set_title("TopoSorted - UE Distribution by FLSI Count", fontsize=16, fontweight='bold')
    ax.tick_params(axis='both', labelsize=15)
    ax.legend(title="FLSI Count", fontsize=12)
    ax.grid(True, axis='y')
    plt.tight_layout()
    bar_path = os.path.join(input_folder, f"{output_prefix}_flsi_bar.pdf")
    plt.savefig(bar_path, bbox_inches='tight')
    print(f"📊 FLSI bar chart saved to: {bar_path}")
    plt.close()


    # Consecutive FLSI bar chart（套用條紋、色彩樣式）
    consec_dist = {}
    for version, df in all_versions.items():
        counts = df['ConsecFLSICount'].value_counts().sort_index()
        consec_dist[version] = counts
    consec_df = pd.DataFrame(consec_dist).fillna(0).astype(int).T

    fig, ax = plt.subplots(figsize=(12, 6))
    width = 0.15
    x = np.arange(len(consec_df.index))

    for i, count in enumerate(consec_df.columns):
        values = consec_df[count].values
        ax.bar(
            x + i * width, values,
            width=width,
            color=custom_colors[i % len(custom_colors)],
            hatch=hatches[i % len(hatches)],
            edgecolor='black',
            label=f'Consec={count}'
        )
        for j, val in enumerate(values):
            if count >= 1:
                xpos = x[j] + i * width
                ax.text(xpos, val + 5, str(val), ha='center', va='bottom',
                        fontsize=8, rotation=0)

    ax.set_xticks(x + width * (len(consec_df.columns) - 1) / 2)
    ax.set_xticklabels(consec_df.index)
    ax.set_xlabel("ITRI Version", fontsize=16, fontweight='bold')
    ax.set_ylabel("Number of UEs", fontsize=16, fontweight='bold')
    # ax.set_title("UE Distribution by ConFLSI Count", fontsize=16, fontweight='bold')
    ax.tick_params(axis='both', labelsize=15)
    ax.legend(
        title="ConFLSI Count",
        title_fontsize=10,
        fontsize=9,
        loc='upper right',
        frameon=False,
        markerscale=0.8,
        handlelength=1.5,
        borderpad=0.3,
        labelspacing=0.3,
        handletextpad=0.5
    )
    ax.grid(True, axis='y')
    plt.tight_layout()
    consec_path = os.path.join(input_folder, f"{output_prefix}_consec_flsi_bar.pdf")
    plt.savefig(consec_path, bbox_inches='tight')
    print(f"📊 Consecutive FLSI bar chart saved to: {consec_path}")
    plt.close()



if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_folder", required=True)
    parser.add_argument("--output_pdf", default="cdf_all_strategies.pdf")
    parser.add_argument("--itri_mode", action="store_true")
    args = parser.parse_args()

    if args.itri_mode:
        analyze_itri_versions(args.input_folder)
    else:
        main(args.input_folder, args.output_pdf)