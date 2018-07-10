{
  Stack Blur v1.0
  
  Original author:
    Mario Klingemann
  Web-site:
    http://incubator.quasimondo.com
  
  Ported to Delphi by
    Igor Kandyba, 07.2018
    
  It is called Stack Blur because this describes best how this
  filter works internally: it creates a kind of moving stack
  of colors whilst scanning through the image. Thereby it
  just has to add one new block of color to the right side
  of the stack and remove the leftmost color. The remaining
  colors on the topmost layer of the stack are either added on
  or reduced by one, depending on if they are on the right or
  on the left side of the stack. 
}

procedure DrawStackBlur(ABmpInOut: TBitmap; const ARadius: Integer);
type
  PColorArray = ^TColorArray;
  TColorArray = Array [0..0] of TColor;

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
  VMin, Kernel: PIntArray;
  Stack: PColorArray;
  ColorRec: PColorRec;
  Radius: Integer;
  RSum, GSum, BSum: Integer;
  RInSum, GInSum, BInSum: Integer;
  ROutSum, GOutSum, BOutSum: Integer;
  StackPointer, StackStart: Integer;
  DivSum, DeltaRadius, AbsoluteRadius: Integer;
  Color: Cardinal;
  W, H, WM, HM, WH, YW, YI, YP: Integer;
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
  DeltaRadius := Radius * 2 + 1;
  YW := 0;
  YI := 0;
  DivSum := (DeltaRadius + 1) shr 1;
  DivSum := DivSum * DivSum;

  // Obtain a pointer to ScanLine
  RowInOut := ABmpInOut.ScanLine[HM];

  // Allocate arrays
  GetMem(R, WH * SizeOf(Integer));
  try
    GetMem(G, WH * SizeOf(Integer));
    try
      GetMem(B, WH * SizeOf(Integer));
      try
        GetMem(VMin, Math.Max(W, H) * SizeOf(Integer));
        try
          GetMem(Kernel, 256 * DivSum * SizeOf(Integer));
          try
            GetMem(Stack, DeltaRadius * SizeOf(TColor));
            try
              // Fill kernel with values
              for i:=0 to 256 * DivSum - 1 do
                Kernel[i] := (i div DivSum);

              for Y:=0 to H - 1 do
              begin
                RSum := 0;
                GSum := 0;
                BSum := 0;
                RInSum := 0;
                GInSum := 0;
                BInSum := 0;
                ROutSum := 0;
                GOutSum := 0;
                BOutSum := 0;

                for i:=-Radius to Radius do
                begin
                  ColorRec := @Stack[i + Radius];
                  ColorRec.Color := RowInOut[YI + Math.Min(WM, Math.Max(i, 0))];
                  AbsoluteRadius := (Radius + 1) - Abs(i);

                  Inc(RSum, (ColorRec.R * AbsoluteRadius));
                  Inc(GSum, (ColorRec.G * AbsoluteRadius));
                  Inc(BSum, (ColorRec.B * AbsoluteRadius));

                  if i > 0 then
                  begin
                    Inc(RInSum, ColorRec.R);
                    Inc(GInSum, ColorRec.G);
                    Inc(BInSum, ColorRec.B);
                  end
                  else
                  begin
                    Inc(ROutSum, ColorRec.R);
                    Inc(GOutSum, ColorRec.G);
                    Inc(BOutSum, ColorRec.B);
                  end;
                end;

                StackPointer := Radius;

                for X:=0 to W - 1 do
                begin
                  R[YI] := Kernel[RSum];
                  G[YI] := Kernel[GSum];
                  B[YI] := Kernel[BSum];

                  Dec(RSum, ROutSum);
                  Dec(GSum, GOutSum);
                  Dec(BSum, BOutSum);

                  StackStart := StackPointer - Radius + DeltaRadius;
                  ColorRec := @Stack[StackStart mod DeltaRadius];

                  Dec(ROutSum, ColorRec.R);
                  Dec(GOutSum, ColorRec.G);
                  Dec(BOutSum, ColorRec.B);

                  if Y = 0 then
                    VMin[X] := Math.Min(X + Radius + 1, WM);

                  ColorRec.Color := RowInOut[YW + VMin[X]];

                  Inc(RInSum, ColorRec.R);
                  Inc(GInSum, ColorRec.G);
                  Inc(BInSum, ColorRec.B);

                  Inc(RSum, RInSum);
                  Inc(GSum, GInSum);
                  Inc(BSum, BInSum);

                  StackPointer := (StackPointer + 1) mod DeltaRadius;
                  ColorRec := @Stack[StackPointer mod DeltaRadius];

                  Inc(ROutSum, ColorRec.R);
                  Inc(GOutSum, ColorRec.G);
                  Inc(BOutSum, ColorRec.B);

                  Dec(RInSum, ColorRec.R);
                  Dec(GInSum, ColorRec.G);
                  Dec(BInSum, ColorRec.B);

                  Inc(YI);
                end;

                Inc(YW, W);
              end;

              for X:=0 to W - 1 do
              begin
                RSum := 0;
                GSum := 0;
                BSum := 0;
                RInSum := 0;
                GInSum := 0;
                BInSum := 0;
                ROutSum := 0;
                GOutSum := 0;
                BOutSum := 0;

                YP := -Radius * W;
                for i:=-Radius to Radius do
                begin
                  YI := Math.Max(0, YP) + X;
                  ColorRec := @Stack[i + Radius];

                  ColorRec.R := R[YI];
                  ColorRec.G := G[YI];
                  ColorRec.B := B[YI];
                  AbsoluteRadius := (Radius + 1) - Abs(i);

                  Inc(RSum, (R[YI] * AbsoluteRadius));
                  Inc(GSum, (G[YI] * AbsoluteRadius));
                  Inc(BSum, (B[YI] * AbsoluteRadius));

                  if i > 0 then
                  begin
                    Inc(RInSum, ColorRec.R);
                    Inc(GInSum, ColorRec.G);
                    Inc(BInSum, ColorRec.B);
                  end
                  else
                  begin
                    Inc(ROutSum, ColorRec.R);
                    Inc(GOutSum, ColorRec.G);
                    Inc(BOutSum, ColorRec.B);
                  end;

                  if i < HM then
                    Inc(YP, W);
                end;

                YI := X;
                StackPointer := Radius;

                for Y:=0 to H - 1 do
                begin
                  RowInOut[YI] := Integer($FF000000) or (Kernel[RSum] shl 16) or (Kernel[GSum] shl 8) or Kernel[BSum];

                  Dec(RSum, ROutSum);
                  Dec(GSum, GOutSum);
                  Dec(BSum, BOutSum);

                  StackStart := StackPointer - Radius + DeltaRadius;
                  ColorRec := @Stack[StackStart mod DeltaRadius];

                  Dec(ROutSum, ColorRec.R);
                  Dec(GOutSum, ColorRec.G);
                  Dec(BOutSum, ColorRec.B);

                  if X = 0 then
                    VMin[Y] := Math.Min(Y + Radius + 1, HM) * W;

                  Color := X + VMin[Y];

                  ColorRec.R := R[Color];
                  ColorRec.G := G[Color];
                  ColorRec.B := B[Color];

                  Inc(RInSum, ColorRec.R);
                  Inc(GInSum, ColorRec.G);
                  Inc(BInSum, ColorRec.B);

                  Inc(RSum, RInSum);
                  Inc(GSum, GInSum);
                  Inc(BSum, BInSum);

                  StackPointer := (StackPointer + 1) mod DeltaRadius;
                  ColorRec := @Stack[StackPointer];

                  Inc(ROutSum, ColorRec.R);
                  Inc(GOutSum, ColorRec.G);
                  Inc(BOutSum, ColorRec.B);

                  Dec(RInSum, ColorRec.R);
                  Dec(GInSum, ColorRec.G);
                  Dec(BInSum, ColorRec.B);

                  Inc(YI, W);
                end;
              end;
            finally
              FreeMem(Stack);
            end;
          finally
            FreeMem(Kernel);
          end;
        finally
          FreeMem(VMin);
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
