import 'package:mocktail/mocktail.dart';

abstract interface class Callable0<TRet> {
  TRet call();
}

class MockCallable0<TRet> extends Mock implements Callable0<TRet> {}

abstract interface class Callable1<TRet, TArg1> {
  TRet call(TArg1 arg1);
}

class MockCallable1<TRet, TArg1> extends Mock
    implements Callable1<TRet, TArg1> {}

abstract interface class Callable2<TRet, TArg1, TArg2> {
  TRet call(TArg1 arg1, TArg2 arg2);
}

class MockCallable2<TRet, TArg1, TArg2> extends Mock
    implements Callable2<TRet, TArg1, TArg2> {}

abstract interface class Callable3<TRet, TArg1, TArg2, TArg3> {
  TRet call(TArg1 arg1, TArg2 arg2, TArg3 arg3);
}

class MockCallable3<TRet, TArg1, TArg2, TArg3> extends Mock
    implements Callable3<TRet, TArg1, TArg2, TArg3> {}

abstract interface class Callable4<TRet, TArg1, TArg2, TArg3, TArg4> {
  TRet call(TArg1 arg1, TArg2 arg2, TArg3 arg3, TArg4 arg4);
}

class MockCallable4<TRet, TArg1, TArg2, TArg3, TArg4> extends Mock
    implements Callable4<TRet, TArg1, TArg2, TArg3, TArg4> {}

abstract interface class Callable5<TRet, TArg1, TArg2, TArg3, TArg4, TArg5> {
  TRet call(TArg1 arg1, TArg2 arg2, TArg3 arg3, TArg4 arg4, TArg5 arg5);
}

class MockCallable5<TRet, TArg1, TArg2, TArg3, TArg4, TArg5> extends Mock
    implements Callable5<TRet, TArg1, TArg2, TArg3, TArg4, TArg5> {}

abstract interface class Callable6<
  TRet,
  TArg1,
  TArg2,
  TArg3,
  TArg4,
  TArg5,
  TArg6
> {
  TRet call(
    TArg1 arg1,
    TArg2 arg2,
    TArg3 arg3,
    TArg4 arg4,
    TArg5 arg5,
    TArg6 arg6,
  );
}

class MockCallable6<TRet, TArg1, TArg2, TArg3, TArg4, TArg5, TArg6> extends Mock
    implements Callable6<TRet, TArg1, TArg2, TArg3, TArg4, TArg5, TArg6> {}

abstract interface class Callable7<
  TRet,
  TArg1,
  TArg2,
  TArg3,
  TArg4,
  TArg5,
  TArg6,
  TArg7
> {
  TRet call(
    TArg1 arg1,
    TArg2 arg2,
    TArg3 arg3,
    TArg4 arg4,
    TArg5 arg5,
    TArg6 arg6,
    TArg7 arg7,
  );
}

class MockCallable7<TRet, TArg1, TArg2, TArg3, TArg4, TArg5, TArg6, TArg7>
    extends Mock
    implements
        Callable7<TRet, TArg1, TArg2, TArg3, TArg4, TArg5, TArg6, TArg7> {}

abstract interface class Callable8<
  TRet,
  TArg1,
  TArg2,
  TArg3,
  TArg4,
  TArg5,
  TArg6,
  TArg7,
  TArg8
> {
  TRet call(
    TArg1 arg1,
    TArg2 arg2,
    TArg3 arg3,
    TArg4 arg4,
    TArg5 arg5,
    TArg6 arg6,
    TArg7 arg7,
    TArg8 arg8,
  );
}

class MockCallable8<
  TRet,
  TArg1,
  TArg2,
  TArg3,
  TArg4,
  TArg5,
  TArg6,
  TArg7,
  TArg8
>
    extends Mock
    implements
        Callable8<
          TRet,
          TArg1,
          TArg2,
          TArg3,
          TArg4,
          TArg5,
          TArg6,
          TArg7,
          TArg8
        > {}

abstract interface class Callable9<
  TRet,
  TArg1,
  TArg2,
  TArg3,
  TArg4,
  TArg5,
  TArg6,
  TArg7,
  TArg8,
  TArg9
> {
  TRet call(
    TArg1 arg1,
    TArg2 arg2,
    TArg3 arg3,
    TArg4 arg4,
    TArg5 arg5,
    TArg6 arg6,
    TArg7 arg7,
    TArg8 arg8,
    TArg9 arg9,
  );
}

class MockCallable9<
  TRet,
  TArg1,
  TArg2,
  TArg3,
  TArg4,
  TArg5,
  TArg6,
  TArg7,
  TArg8,
  TArg9
>
    extends Mock
    implements
        Callable9<
          TRet,
          TArg1,
          TArg2,
          TArg3,
          TArg4,
          TArg5,
          TArg6,
          TArg7,
          TArg8,
          TArg9
        > {}
