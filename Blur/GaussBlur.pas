{
  Fast Gaussian Blur v1.3
  
  Original author:
    Mario Klingemann
  Web-site:
    http://incubator.quasimondo.com
  
  Ported by
    Igor Kandyba, 07.2018
    
  It uses a special trick by first making a horizontal blur 
  on the original image and afterwards making a vertical blur 
  on the pre-processed image. This is a mathematical correct 
  thing to do and reduces the calculation a lot.
}

procedure DrawGaussBlur(ABmpInOut: TBitmap; const ARadius: Integer);
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
  R1, G1, B1: PIntArray;
  R2, G2, B2: PIntArray;
  Kernel: PIntArray;
  Mult: Array of Array of Integer;
  ColorRec: TColorRec;
  KernelSize: Integer;
  Radius: Integer;
  CR, CG, CB: Integer;
  Sum: Integer;
  Read: Integer;
  Delta: Integer;
  w, h, wh: Integer;
  yi, xl, yl, ym, ri, iw, riw, szi: Integer;
  x, y: Integer;
  i, j: Integer;
begin
  if not Assigned(ABmpInOut) or (ARadius < 1) or (ABmpInOut.PixelFormat <> pf32bit) then
    Exit;

  w := ABmpInOut.Width;
  h := ABmpInOut.Height;
  x := 0;
  y := 0;
  iw := W;
  wh := iw * h;
  RowInOut := ABmpInOut.ScanLine[h - 1];

  Radius := Math.Min(Math.Max(1, ARadius), 248);
  Delta := (Radius * 2) + 1;
  KernelSize := Delta;

  GetMem(Kernel, Delta * SizeOf(Integer));
  try
    SetLength(Mult, Delta * SizeOf(Integer), 256 * SizeOf(Integer));

    Sum := 0;
    szi := 0;
    for i:=1 to Radius do
    begin
      szi := Radius - i;
      Kernel[Radius + i] := szi * szi;
      Kernel[szi] := szi * szi;
      Inc(Sum, Kernel[szi] + Kernel[szi]);

      for j:=0 to 256 do
      begin
        Mult[Radius + i][j] := Kernel[szi] * j;
        Mult[szi][j] := Kernel[szi] * j;
      end;
    end;

    Kernel[Radius] := Radius * Radius;
    Inc(Sum, Kernel[Radius]);

    for j:=0 to 256 do
      Mult[Radius][j] := Kernel[Radius] * j;

    GetMem(R1, wh * SizeOf(Integer));
    try
      GetMem(G1, wh * SizeOf(Integer));
      try
        GetMem(B1, wh * SizeOf(Integer));
        try
          GetMem(R2, wh * SizeOf(Integer));
          try
            GetMem(G2, wh * SizeOf(Integer));
            try
              GetMem(B2, wh * SizeOf(Integer));
              try
                for i:=0 to wh - 1 do
                begin
                  ColorRec.Color := RowInOut[i];
                  R1[i]:= ColorRec.R;
                  G1[i] := ColorRec.G;
                  B1[i] := ColorRec.B;
                end;

                x := Math.Max(0, x);
                y := Math.Max(0, y);
                w := x + w - Math.Max(0, (x + w) - iw);
                h := y + h - Math.Max(0, (y + h) - ABmpInOut.Height);
                yi := y * iw;

                for yl:=y to h - 1 do
                begin
                  for xl:=x to w -1 do
                  begin
                    CB := 0;
                    CG := 0;
                    CR := 0;
                    Sum := 0;
                    ri := xl - Radius;
                    for i:=0 to KernelSize - 1 do
                    begin
                      Read := ri + i;
                      if (Read >= x) and (Read < w) then
                      begin
                        Read := Read + yi;
                        Inc(CR, Mult[i][R1[Read]]);
                        Inc(CG, Mult[i][G1[Read]]);
                        Inc(CB, Mult[i][B1[Read]]);

                        Inc(Sum, Kernel[i]);
                      end;
                    end;

                    ri := yi + xl;
                    R2[ri] := CR div Sum;
                    G2[ri] := CG div Sum;
                    B2[ri] := CB div Sum;
                  end;

                  Inc(yi, iw);
                end;

                yi := y * iw;

                for yl:=y to h - 1 do
                begin
                  ym := yl - Radius;
                  riw := ym * iw;
                  for xl:=x to w - 1 do
                  begin
                    CR := 0;
                    CG := 0;
                    CB := 0;
                    Sum := 0;
                    ri := ym;
                    Read := xl + riw;
                    for i:=0 to KernelSize - 1 do
                    begin
                      if (ri < h) and (ri >= y) then
                      begin
                        Inc(CR, Mult[i][R2[Read]]);
                        Inc(CG, Mult[i][G2[Read]]);
                        Inc(CB, Mult[i][B2[Read]]);

                        Inc(Sum, Kernel[i]);
                      end;

                      Inc(ri);
                      Inc(Read, iw);
                    end;

                    RowInOut[xl + yi] := Integer($FF000000) or ((CR div Sum) shl 16) or ((CG div Sum) shl 8) or (CB div Sum);
                  end;

                  Inc(yi, iw);
                end;
              finally
                FreeMem(B2);
              end;
            finally
              FreeMem(G2);
            end;
          finally
            FreeMem(R2);
          end;
        finally
          FreeMem(B1);
        end;
      finally
        FreeMem(G1);
      end;
    finally
      FreeMem(R1);
    end;
  finally
    FreeMem(Kernel);
  end;
end;
