/**
 * Created by zerov on 06 19 2025.
 */

@IsTest
private class MyIterableTest {

    @IsTest
    static void testIterableForLoop() {
        List<String> strings = new List<String> {'Hello','World'};
        MyIterable tstIterator = new MyIterable(strings);

    for(String str : tstIterator){
        System.debug(str);
        }
    }
}
