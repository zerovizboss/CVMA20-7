/**
 * Created by zerov on 06 19 2025.
 */

public class MyIterable implements Iterable<String> {

    private final List<String> strings;

    public MyIterable (List<String> strings){
        this.strings = strings;
    }

    public Iterator<String> iterator() {
        return strings.iterator();
    }

}