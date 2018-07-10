{
  Super Fast Blur v1.1
  
  Original author:
    Mario Klingemann
  Web-site:
    http://incubator.quasimondo.com
  
  Ported by
    Igor Kandyba, 07.2018
    
  Tip: Multiple invovations of this filter with a small 
  radius will approximate a gaussian blur quite well.
}

procedure DrawBoxBlur(ABmpInOut: TBitmap; const ARadius: Integer);
type
  PIntArray = ^TIntArray;
  TIntArray = Array [0..0] of Integer;

  PColorRec = ^TColorRec;
  TColorRec = Packed Record
  case Cardinal of
    0: (Color: Cardinal);
    1: (B, G, R, A: Byte);
  end;

var
  RowInOut: PIntArray;
  R, G, B: PIntArray;
  VMax, VMin: PIntArray;
  Kernel: PIntArray;
  ColorRec1, ColorRec2: TColorRec;
  Radius: Integer;
  RSum, GSum, BSum: Integer;
  DivSum: Integer;
  Color1, Color2: Cardinal;
  W, H: Integer;
  WH, WM, HM, YW, YI, YP: Integer;
  X, Y: Integer;
  i: Integer;
begin
  if not Assigned(ABmpInOut) or (ARadius < 1) or (ABmpInOut.PixelFormat <> pf32bit) then
    Exit;

  Radius := ARadius;
  W := ABmpInOut.Width;
  H := ABmpInOut.Height;
  WM := W - 1;
  HM := H - 1;
  WH := W * H;
  YW := 0;
  YI := 0;
  DivSum := Radius * 2 + 1;

  // Obtain a pointer to ScanLine
  RowInOut := ABmpInOut.ScanLine[HM];

  // Allocate arrays
  GetMem(R, WH * SizeOf(Integer));
  try
    GetMem(G, WH * SizeOf(Integer));
    try
      GetMem(B, WH * SizeOf(Integer));
      try
        GetMem(VMax, Math.Max(W, H) * SizeOf(Integer));
        try
          GetMem(VMin, Math.Max(W, H) * SizeOf(Integer));
          try
            GetMem(Kernel, 256 * DivSum * SizeOf(Integer));
            try
              // Fill kernel with values
              for i:=0 to 256 * DivSum - 1 do
                Kernel[i] := (i div DivSum);

              for Y:=0 to H - 1 do
              begin
                RSum := 0;
                GSum := 0;
                BSum := 0;

                for i:=-Radius to Radius do
                begin
                  ColorRec1.Color := RowInOut[YI + Math.Min(WM, Math.Max(i, 0))];
                  Inc(RSum, ColorRec1.R);
                  Inc(GSum, ColorRec1.G);
                  Inc(BSum, ColorRec1.B);
                end;

                for X:=0 to W - 1 do
                begin
                  R[YI] := Kernel[RSum];
                  G[YI] := Kernel[GSum];
                  B[YI] := Kernel[BSum];

                  if Y = 0 then
                  begin
                    VMax[X] := Math.Max(X - Radius, 0);
                    VMin[X] := Math.Min(X + Radius + 1, WM);
                  end;

                  ColorRec1.Color := RowInOut[YW + VMax[X]];
                  ColorRec2.Color := RowInOut[YW + VMin[X]];

                  Inc(RSum, ColorRec2.R - ColorRec1.R);
                  Inc(GSum, ColorRec2.G - ColorRec1.G);
                  Inc(BSum, ColorRec2.B - ColorRec1.B);

                  Inc(YI);
                end;

                Inc(YW, W);
              end;

              for X:=0 to W - 1 do
              begin
                RSum := 0;
                GSum := 0;
                BSum := 0;

                YP := -Radius * W;

                for i:=-Radius to Radius do
                begin
                  YI := Math.Max(0, YP) + X;
                  Inc(RSum, R[YI]);
                  Inc(GSum, G[YI]);
                  Inc(BSum, B[YI]);

                  Inc(YP, W);
                end;

                YI := X;

                for Y:=0 to H - 1 do
                begin
                  RowInOut[YI] := Integer($FF000000) or (Kernel[RSum] shl 16) or (Kernel[GSum] shl 8) or Kernel[BSum];

                  if X = 0 then
                  begin
                    VMax[Y] := Math.Max(Y - Radius, 0) * W;
                    VMin[Y] := Math.Min(Y + Radius + 1, HM) * W;
                  end;

                  Color1 := X + VMax[Y];
                  Color2 := X + VMin[Y];

                  Inc(RSum, R[Color2] - R[Color1]);
                  Inc(GSum, G[Color2] - G[Color1]);
                  Inc(BSum, B[Color2] - B[Color1]);

                  Inc(YI, W);
                end;
              end;
            finally
              FreeMem(Kernel);
            end;
          finally
            FreeMem(VMin);
          end;
        finally
          FreeMem(VMax);
        end;
      finally
        FreeMem(B);
      end;
    finally
      FreeMem(G);
    end;
  finally
    FreeMem(R);
  end;
end;
