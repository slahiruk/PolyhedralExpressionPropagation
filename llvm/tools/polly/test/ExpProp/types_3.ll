; RUN: opt %loadPolly -polly-exp -polly-exp-heuristic=0 -analyze < %s | FileCheck %s
; RUN: opt %loadPolly -polly-exp -polly-exp-heuristic=0 -polly-codegen -S < %s | FileCheck %s --check-prefix=IR
;
;    void f(int *A, float *B) {
;      for (int i = 0; i < 100; i++)
;        A[i] = i + 1;
;      for (int i = 0; i < 100; i++)
;        B[i] = A[i] + 3.0;
;    }
;
; CHECK:         Statements {
; CHECK-NEXT:    	Stmt_for_body
; CHECK-NEXT:            Domain :=
; CHECK-NEXT:                { Stmt_for_body[i0] : 0 <= i0 <= 99 };
; CHECK-NEXT:            Schedule :=
; CHECK-NEXT:                { Stmt_for_body[i0] -> [0, i0] };
; CHECK-NEXT:            MustWriteAccess :=	[Reduction Type: NONE] [Scalar: 0]
; CHECK-NEXT:                { Stmt_for_body[i0] -> MemRef_A[i0] };
; CHECK-NEXT:    	Stmt_for_body4	 [#Recompute Values: 1]
; CHECK-NEXT:            Domain :=
; CHECK-NEXT:                { Stmt_for_body4[i0] : 0 <= i0 <= 99 };
; CHECK-NEXT:            Schedule :=
; CHECK-NEXT:                { Stmt_for_body4[i0] -> [1, i0] };
; CHECK-NEXT:            MustWriteAccess :=	[Reduction Type: NONE] [Scalar: 0]
; CHECK-NEXT:                { Stmt_for_body4[i0] -> MemRef_B[i0] };
; CHECK-NEXT:    }
;
; IR: polly.stmt.for.body4:                             ; preds = %polly.loop_header3
; IR:   %p_indvars.iv.next2 = add nuw nsw i64 %polly.indvar6, 1
; IR:   %p_tmp = trunc i64 %p_indvars.iv.next2 to i32
; IR:   %p_conv = sitofp i32 %p_tmp to double
; IR:   %p_add7 = fadd double %p_conv, 3.000000e+00
; IR:   %p_conv8 = fptrunc double %p_add7 to float
; IR:   %scevgep9 = getelementptr float, float* %B, i64 %polly.indvar6
; IR:   store float %p_conv8, float* %scevgep9
;
source_filename = "/home/johannes/projects/llvm/polly/test/ExpProp/types_3.c"
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

define void @f(i32* %A, float* %B) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv1 = phi i64 [ %indvars.iv.next2, %for.inc ], [ 0, %entry ]
  %exitcond3 = icmp ne i64 %indvars.iv1, 100
  br i1 %exitcond3, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %indvars.iv.next2 = add nuw nsw i64 %indvars.iv1, 1
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv1
  %tmp = trunc i64 %indvars.iv.next2 to i32
  store i32 %tmp, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  br label %for.cond

for.end:                                          ; preds = %for.cond
  br label %for.cond2

for.cond2:                                        ; preds = %for.inc11, %for.end
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc11 ], [ 0, %for.end ]
  %exitcond = icmp ne i64 %indvars.iv, 100
  br i1 %exitcond, label %for.body4, label %for.end13

for.body4:                                        ; preds = %for.cond2
  %arrayidx6 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp4 = load i32, i32* %arrayidx6, align 4
  %conv = sitofp i32 %tmp4 to double
  %add7 = fadd double %conv, 3.000000e+00
  %conv8 = fptrunc double %add7 to float
  %arrayidx10 = getelementptr inbounds float, float* %B, i64 %indvars.iv
  store float %conv8, float* %arrayidx10, align 4
  br label %for.inc11

for.inc11:                                        ; preds = %for.body4
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond2

for.end13:                                        ; preds = %for.cond2
  ret void
}
