本科学的通信读研了没在做，这也算是出于兴趣完成的工程，难免有纰漏，后续会抽空将本工程逐渐完善。若有任何问题，非常欢迎您通过邮箱联系我lauchinyuan@yeah.net，共同学习，不过近来比较忙，回复可能稍慢，见谅。

### 关于本项目

本项目是使用Verilog硬件描述语言编写的可以部署在FPGA平台上的正交相移键控（Quadrature Phase Shift Keying，QPSK）调制解调器，使用的调制方案为IQ正交调制，解调端使用Gardner环实现位同步。采用了vivado IP核实现FIR滤波器、乘法器、DDS直接数字频率合成器，这些IP核可以用quartus IP核或者其他厂商提供的IP来替代。

#### 功能说明

整体功能为发送端产生时分秒时钟数据，并将这一数据封装成带有帧头和校验和的数据帧，每一个数据帧设定为40bit，即帧头(8bit)+时(8bit)+分(8bit)+秒(8bit)+校验和(8bit)，通过QPSK调制器将这一数据调制成QPSK信号。接收端接受这一信号，并进行载波同步和位同步，抽样判决得到解调后的二进制数据，最后解析这一数据，在接收端实现时钟数据的数码管动态显示。本项目的核心为QPSK调制解调器，具体传送的数据可以自定义，并不一定是时钟数据。

#### 模块结构

本工程RTL视图如图1所示

![RTL视图](image/RTL.png)

<center>图1. RTL视图</center>

各个模块的功能解释如下：

- clk_gen:时钟生成模块，产生时分秒时钟信号，用于后续生成40bit原始数据，在设计中每秒更新一次数据。
- data_gen:数据生成模块，结合所设定的帧头，时钟数据，计算校验和，并生成40bit数据
- qpsk_mod:调制模块，其主要子模块有
  - para2ser:将40bit并行数据转换为串行数据流，在本设计中高位先发
  - iq_div:将串行数据流依据其奇偶位置，分为I(正交)、Q(同向)两路
  - rcosfilter:升余弦滤波器，使用FIR滤波器实现，对I、Q两路数据进行成形滤波
  - dds:直接数字频率合成信号发生器，产生正弦、余弦载波
- qpsk_demod:解调模块，其主要子模块有
  - gardner_sync:Gardner环，用于实现位同步，判断最佳的抽样判决点，并进行抽样判决，输出抽判数据，gardner环主要的子模块有：
    - interpolate_filter:内插滤波器，计算内插值
    - gardner_ted:Gardner:定时误差检测，包含环形滤波器
    - nco：nco递减计数模块，生成抽样判决标志信号
  - dds:直接数字频率合成信号发生器，产生正弦、余弦载波
  - iq_comb:将抽样判决后的I、Q两路数据重新整合成一路串行数据输出
  - data_valid:数据有效性检测模块，检测帧头和校验和是否正确，若正确，输出最终的40bit数据结果
- time_display:时钟数据显示模块，依据收到的40bit数据，解析时钟信息，并在数码管上显示，对数据个位和十位的分离，采用了bcd编码方案。

### 设计思路

#### QPSK基本原理

QPSK全称为正交相移键控（Quadrature Phase Shift Keying），简单来说就是利用四种不同的相位来代表不同的信息的数字调制解调技术。其信号表示为：$$S_i(t) = Acos(\omega_ct+\theta_i),i=1,2,3,4,0<t<T_s$$

#### 调制端设计

对于调制过程，其结构如图2所示。将I、Q两路数据流转换为双极性信号(+1/-1)，分别与余弦信号、正弦信号相乘，然后再相加，得到的信号表达式为：$$S_i(t)=Icos(\omega_ct)+Qsin(\omega_ct)$$

得到的信号与I、Q两路双极性数据之间的对应关系如表1所示，即通过两路同频的正余弦载波信号的相加可以实现混合信号的四个不同相位。

<center> 表1. I、Q数据与QPSK调制信号的映射</center>

$$
\begin{array}{|c|c|c|}
\hline
{I} & {Q} & {S_i(t)}  \\
\hline
{+1} & {-1} & {\sqrt{2}cos(2\omega_ct+\pi/4)} \\
\hline
{-1} & {-1} & {\sqrt{2}cos(2\omega_ct+3\pi/4)} \\
\hline
{-1} & {+1} & {\sqrt{2}cos(2\omega_ct+5\pi/4)} \\
\hline
{+1} & {+1} & {\sqrt{2}cos(2\omega_ct+7\pi/4)} \\
\hline
\end{array}
$$

##### IQ分流

输入的原始数据流的每一bit是具有确定周期(本设计中为0.2ms)的比特流，QPSK调制过程需要将这些bit流依据其所在位置分为I(正交)、Q(同向)两路，在RTL设计中，依据所用的采样时钟频率(本设计中为500kHz)配置计数器，每一个采样时钟自加1，当计数器计数一定次数(本设计中为100次)，即完成一个通道一个bit的采样，接着继续采样，但将采样数据输出到另一通道，并重新开始计数，往复循环。在FPGA实现中，IQ分流模块和产生数据流的data_gen模块的复位信号`rst_n`是同一个信号，在理想条件下，两个模块同时离开复位模式，开启正常工作，故可以确保IQ分流模块的计数器是从数据边沿开始计数，计到100正好需要转换数据通道。

##### 成形滤波

其中的关键部件是成形滤波器，成形滤波的作用是平滑波形效果，提高频谱的利用率，并消除码间串扰。

本设计中成型滤波为平方根升余弦低通FIR滤波器。通过MATLAB Filter Designer工具，配置相应的滤波器参数(如滤波器阶数，窗函数等)可以生成滤波器抽头系数，将生成的抽头系数文件(例如Vivado支持的coe文件)导入到FIR滤波器IP核，并配置相应的IP核参数，即可实例化调用相应IP实现成形滤波器。对于本设计中的其他滤波器也是同样的设计思路。

![QPSK调制器结构](image/mod_structure.png)

<center>图2. QPSK调制器结构</center>



#### 解调端设计

在整体QPSK调制解调过程中，存在成型滤波、低通滤波等滤波过程，这些滤波器参数的设置影响了QPSK调制解调的性能，同时，QPSK的码元速率、载波频率等因素也会影响到通信质量。所以在编写Verilog代码前，通过编写MATLAB仿真程序，对QPSK调制解调的基本过程进行仿真，以确认相关参数的设计的正确性。

### 设计参数

通过MATLAB仿真和实际功能需求，确定本设计的相关参数如下：

- 调制端载波频率：50kHz
- 帧长度：40bit
- 采样率：500kHz
- 发送端每bit采样100次

综上，每秒可以传送的帧数为：$N_f =500000 \div (40\times 100)=125$

### 进展规划

- [x] 完成QPSK调制解调过程MATLAB仿真

- [x] verilog实现QPSK调制解调基本过程
- [x] 实现QPSK解调端的Gardner位同步
- [x] 实现数字时钟数据生成和显示
- [ ] 加入噪声，仿真加噪后结果
- [ ] 新增mod branch和demod branch,将调制端和解调端分开，并在两台FPGA硬件设备上部署
- [ ] 编写blog，详细讲述本项目的实施细节和QPSK原理
