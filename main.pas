unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls, Math;

const
  n = 513;
  a = 0;
  b = 1;
  h = (b - a)/n;
  tau = 0.1;
  High_Val = 1;
  Low_Val = 0;

type
  SingleArr = array [0..N, 0..N] of single;
  PSingleArr = ^SingleArr;

type

  { TWaveForm }

  TWaveForm = class(TForm)
    Timer: TTimer;
    WavePB: TPaintBox;
    procedure FormShow(Sender: TObject);
    procedure TimerStartTimer(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure TimerTimerSSE(Sender: TObject);
    procedure Paint;
  public
    SSE: boolean;
    isFirst: boolean;
     t: integer;
  end;

var
  WaveForm: TWaveForm;
  Mat_u, Mat_v: SingleArr;

const
  four: array[1..4] of single = (-4, -4, -4, -4);
  tau_arr: array[1..4] of single = (tau, tau, tau, tau);

implementation

var
  idx: integer;

function Get_x(i: integer) : double;
begin
  Get_x := a + i*h;
end;

function Get_y(i: integer) : double;
begin
  Get_y := a + i*h;
end;

function Get_t(i: integer) : double;
begin
  Get_t := i*tau;
end;

function f(x: double; y: double; t: double) : double;
begin
  f := 0;
end;

function g(x: double; y: double; t: double) : double;
begin
  //g := sin((Get_x(i))*Pi) - 0.5;
  g := Power(2.7818281828, -25*(sqr(x - 0.5) + sqr(y - 0.5)));
end;

{$R *.lfm}
{$asmmode intel}

{ TWaveForm }

procedure TWaveForm.TimerStartTimer(Sender: TObject);
var
  i, j, k: integer;
begin
  t := 0;
  for i := 0 to n do begin
    for j := 0 to n do begin
      Mat_v[i][j] := 0;
      Mat_u[i][j] := g(Get_x(i), Get_y(j), Get_t(0));
    end;
  end;
  Paint;
end;

procedure TWaveForm.FormShow(Sender: TObject);
begin
  SSE := True;
  if SSE then
    Timer.OnTimer := @TimerTimerSSE;
end;

procedure TWaveForm.TimerTimerSSE(Sender: TObject);
var
  s, i, j: integer;
begin
  for s := 1 to 100 do begin
    inc(t);
    for i := 1 to n - 1 do begin
      j := 1;
      while j <= n - 1 do begin
        idx := 4*((n + 1)*i + j);
        asm
          mov eax, [idx]
          movups xmm0, [Mat_u + eax + (n + 1)*4]
          movups xmm1, [Mat_u + eax + 4]
          addps xmm0, xmm1
          movups xmm1, [Mat_u + eax]
          movups xmm2, [four]
          mulps xmm1, xmm2
          addps xmm0, xmm1
          movups xmm1, [Mat_u + eax - (n + 1)*4]
          addps xmm0, xmm1
          movups xmm1, [Mat_u + eax - 4]
          addps xmm0, xmm1
          movups xmm1, [tau_arr]
          mulps xmm0, xmm1
          movups xmm1, [Mat_v + eax]
          addps xmm1, xmm0
          movups [Mat_v + eax], xmm1
        end;
        j += 4;
      end;
    end;
    for i := 1 to n - 1 do begin
      j := 1;
      while j <= n - 1 do begin
        idx := 4*((n + 1)*i + j);
        asm
          mov eax, [idx]
          movups xmm0, [Mat_u + eax]
          movups xmm1, [Mat_v + eax]
          movups xmm2, [tau_arr]
          mulps xmm1, xmm2
          addps xmm0, xmm1
          movups [Mat_u + eax], xmm0
        end;
        j += 4;
      end;
    end;
    for i := 1 to n - 1 do begin
      Mat_u[i][0] := Mat_u[i][1];
      Mat_u[i][n] := Mat_u[i][n - 1];
      Mat_v[i][0] := Mat_v[i][1];
      Mat_v[i][n] := Mat_v[i][n - 1];
    end;
    for j := 0 to n do begin
      Mat_u[0][j] := Mat_u[1][j];
      Mat_u[n][j] := Mat_u[n - 1][j];
      Mat_v[0][j] := Mat_v[1][j];
      Mat_v[n][j] := Mat_v[n - 1][j];
    end;
  end;
  Paint;
end;

procedure TWaveForm.TimerTimer(Sender: TObject);
var
  s, i, j: integer;
begin
  for s := 1 to 100 do begin
    inc(t);
    for i := 1 to n - 1 do
      for j := 1 to n - 1 do
        Mat_v[i][j] += ((Mat_u[i + 1][j] + Mat_u[i][j + 1] - 4*Mat_u[i][j] +
          Mat_u[i - 1][j] + Mat_u[i][j - 1]))*tau;
    for i := 1 to n - 1 do
      for j := 1 to n - 1 do
        Mat_u[i][j] += Mat_v[i][j]*tau;
    for i := 1 to n - 1 do begin
      Mat_u[i][0] := Mat_u[i][1];
      Mat_u[i][n] := Mat_u[i][n - 1];
      Mat_v[i][0] := Mat_v[i][1];
      Mat_v[i][n] := Mat_v[i][n - 1];
    end;
    for j := 0 to n do begin
      Mat_u[0][j] := Mat_u[1][j];
      Mat_u[n][j] := Mat_u[n - 1][j];
      Mat_v[0][j] := Mat_v[1][j];
      Mat_v[n][j] := Mat_v[n - 1][j];
    end;
  end;
  Paint;
end;

function GetColor(Value: double): TColor;
var V: double;
begin
  V := min(abs(Low_Val + (Value - Low_Val)/(High_Val - Low_Val)), 1);
  Result := (Round($FF*V) mod $100);
  if Value < 0 then
     Result *= $100;
end;

procedure TWaveForm.Paint;
var
  i, j: integer;
  Colors: array[0..n, 0..n] of TColor;
begin
  for i := 0 to n do
    for j := 0 to n do
      Colors[i][j] := GetColor(Mat_u[i][j]);

  for i := 0 to n do
    for j := 0 to n do
      WavePB.Canvas.Pixels[i, j] := Colors[i][j];
end;

end.

