import QtQuick
import QtTest
import "../components/Clamp.js" as Clamp

// A share, a level or how far along something is, held between 0 and 1.
TestCase {
    name: "Clamp"

    function test_aShareStaysBetweenNoneAndAll_data() {
        return [
            { tag: "below", value: -0.2, held: 0 },
            { tag: "none", value: 0, held: 0 },
            { tag: "between", value: 0.42, held: 0.42 },
            { tag: "all", value: 1, held: 1 },
            { tag: "past", value: 1.3, held: 1 }
        ];
    }

    function test_aShareStaysBetweenNoneAndAll(data) {
        compare(Clamp.unit(data.value), data.held);
    }
}
